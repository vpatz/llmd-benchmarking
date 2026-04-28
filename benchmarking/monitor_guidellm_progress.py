#!/usr/bin/env python3
"""Poll a running GuideLLM job and summarize real progress.

This script is meant to answer the operational question:
"Is the benchmark actually doing work, or is it just hanging?"

It combines three live signal sources:
1. The Kubernetes Job / benchmark pod state
2. Benchmark output artifact creation under /results
3. vLLM /metrics counters from all worker pods behind the target service

Example:
    python3 benchmarking/monitor_guidellm_progress.py \
      --namespace varun-benchmark \
      --job guidellm-benchmark-job-1-1-granite4-7b-tiny \
      --service granite4-7b-tiny-nvidia-r4-tp1 \
      --artifact-prefix 1-1-granite4-7b-tiny-r4-tp1-final \
      --interval 20
"""

from __future__ import annotations

import argparse
import json
import shlex
import subprocess
import sys
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Dict, Iterable, List, Optional, Tuple


def run_oc(args: List[str], check: bool = True) -> str:
    proc = subprocess.run(
        ["oc", *args],
        text=True,
        capture_output=True,
    )
    if check and proc.returncode != 0:
        raise RuntimeError(proc.stderr.strip() or proc.stdout.strip() or "oc command failed")
    return proc.stdout


def run_oc_json(args: List[str]) -> Dict:
    return json.loads(run_oc([*args, "-o", "json"]))


def now_utc() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")


def parse_metric_value(metrics_text: str, metric_name: str, labels: Optional[Dict[str, str]] = None) -> float:
    for line in metrics_text.splitlines():
        if not line or line.startswith("#"):
            continue
        if not line.startswith(metric_name):
            continue
        if labels is None:
            try:
                return float(line.rsplit(" ", 1)[1])
            except Exception:
                continue
        if "{" not in line:
            continue
        label_str = line[line.index("{") + 1 : line.index("}")]
        parts = {}
        for chunk in label_str.split(","):
            if "=" not in chunk:
                continue
            key, value = chunk.split("=", 1)
            parts[key] = value.strip('"')
        if all(parts.get(k) == v for k, v in labels.items()):
            try:
                return float(line.rsplit(" ", 1)[1])
            except Exception:
                continue
    return 0.0


def human_bytes(size: int) -> str:
    units = ["B", "KiB", "MiB", "GiB", "TiB"]
    value = float(size)
    for unit in units:
        if value < 1024.0 or unit == units[-1]:
            return f"{value:.1f}{unit}" if unit != "B" else f"{int(value)}B"
        value /= 1024.0
    return f"{size}B"


@dataclass
class ArtifactInfo:
    name: str
    size_bytes: int


def get_job_summary(namespace: str, job_name: str) -> Tuple[Dict[str, Optional[str]], Optional[Dict]]:
    job = run_oc_json(["get", "job", job_name, "-n", namespace])
    status = job.get("status", {})
    pod_list = run_oc_json(["get", "pod", "-n", namespace, "-l", f"job-name={job_name}"])
    pod = pod_list.get("items", [None])[0]
    return (
        {
            "active": str(status.get("active", 0)),
            "succeeded": str(status.get("succeeded", 0)),
            "failed": str(status.get("failed", 0)),
            "start_time": status.get("startTime"),
            "completion_time": status.get("completionTime"),
        },
        pod,
    )


def get_artifacts(namespace: str, pod_name: str, artifact_prefix: str) -> List[ArtifactInfo]:
    script = (
        "python3 - <<'PY'\n"
        "from pathlib import Path\n"
        f"prefix = {artifact_prefix!r}\n"
        "for path in sorted(Path('/results').glob(prefix + '.*')):\n"
        "    try:\n"
        "        print(f'{path.name}\\t{path.stat().st_size}')\n"
        "    except FileNotFoundError:\n"
        "        pass\n"
        "PY"
    )
    out = run_oc(
        [
            "exec",
            "-n",
            namespace,
            pod_name,
            "--",
            "/bin/sh",
            "-lc",
            script,
        ],
        check=False,
    )
    artifacts: List[ArtifactInfo] = []
    for line in out.splitlines():
        if "\t" not in line:
            continue
        name, size = line.split("\t", 1)
        try:
            artifacts.append(ArtifactInfo(name=name, size_bytes=int(size)))
        except ValueError:
            continue
    return artifacts


def get_worker_pods(namespace: str, service_name: str) -> List[str]:
    data = run_oc_json(
        ["get", "pods", "-n", namespace, "-l", f"app.kubernetes.io/name={service_name}"]
    )
    pods: List[str] = []
    for item in data.get("items", []):
        if item.get("metadata", {}).get("deletionTimestamp"):
            continue
        if item.get("status", {}).get("phase") != "Running":
            continue
        pods.append(item["metadata"]["name"])
    return sorted(pods)


def get_worker_metrics(namespace: str, pod_name: str) -> Dict[str, float]:
    metrics = run_oc(
        [
            "exec",
            "-n",
            namespace,
            pod_name,
            "-c",
            "main",
            "--",
            "/bin/sh",
            "-lc",
            "curl -ks https://127.0.0.1:8000/metrics",
        ],
        check=False,
    )
    return {
        "running": parse_metric_value(metrics, "vllm:num_requests_running"),
        "waiting": parse_metric_value(metrics, "vllm:num_requests_waiting"),
        "prompt_tokens_total": parse_metric_value(metrics, "vllm:prompt_tokens_total"),
        "generation_tokens_total": parse_metric_value(metrics, "vllm:generation_tokens_total"),
        "success_length": parse_metric_value(
            metrics,
            "vllm:request_success_total",
            {"finished_reason": "length"},
        ),
        "success_stop": parse_metric_value(
            metrics,
            "vllm:request_success_total",
            {"finished_reason": "stop"},
        ),
        "success_abort": parse_metric_value(
            metrics,
            "vllm:request_success_total",
            {"finished_reason": "abort"},
        ),
        "success_error": parse_metric_value(
            metrics,
            "vllm:request_success_total",
            {"finished_reason": "error"},
        ),
    }


def sum_dicts(items: Iterable[Dict[str, float]]) -> Dict[str, float]:
    total: Dict[str, float] = {}
    for item in items:
        for key, value in item.items():
            total[key] = total.get(key, 0.0) + value
    return total


def summarize(namespace: str, job_name: str, service_name: str, artifact_prefix: str) -> str:
    job_status, pod = get_job_summary(namespace, job_name)
    pod_name = pod["metadata"]["name"] if pod else None
    pod_phase = pod.get("status", {}).get("phase") if pod else "missing"
    pod_ready = "0/0"
    pod_restarts = 0
    if pod:
        statuses = pod.get("status", {}).get("containerStatuses", [])
        ready_count = sum(1 for s in statuses if s.get("ready"))
        pod_ready = f"{ready_count}/{len(statuses)}"
        pod_restarts = sum(int(s.get("restartCount", 0)) for s in statuses)

    artifacts: List[ArtifactInfo] = []
    if pod_name and pod_phase in {"Running", "Succeeded"}:
        artifacts = get_artifacts(namespace, pod_name, artifact_prefix)

    worker_pods = get_worker_pods(namespace, service_name)
    worker_metrics = sum_dicts(get_worker_metrics(namespace, name) for name in worker_pods)

    success_total = (
        worker_metrics.get("success_length", 0.0)
        + worker_metrics.get("success_stop", 0.0)
        + worker_metrics.get("success_abort", 0.0)
        + worker_metrics.get("success_error", 0.0)
    )

    artifact_summary = (
        ", ".join(f"{a.name}={human_bytes(a.size_bytes)}" for a in artifacts) if artifacts else "none"
    )

    return (
        f"[{now_utc()}] "
        f"job(active={job_status['active']}, succeeded={job_status['succeeded']}, failed={job_status['failed']}) "
        f"pod(name={pod_name or 'missing'}, phase={pod_phase}, ready={pod_ready}, restarts={pod_restarts}) "
        f"workers={len(worker_pods)} "
        f"running={int(worker_metrics.get('running', 0.0))} "
        f"waiting={int(worker_metrics.get('waiting', 0.0))} "
        f"success={int(success_total)} "
        f"errors={int(worker_metrics.get('success_error', 0.0))} "
        f"prompt_tokens={int(worker_metrics.get('prompt_tokens_total', 0.0))} "
        f"gen_tokens={int(worker_metrics.get('generation_tokens_total', 0.0))} "
        f"artifacts={artifact_summary}"
    )


def main() -> int:
    parser = argparse.ArgumentParser(description="Monitor GuideLLM job progress via oc + vLLM metrics.")
    parser.add_argument("--namespace", required=True, help="Kubernetes namespace")
    parser.add_argument("--job", required=True, help="GuideLLM Job name")
    parser.add_argument("--service", required=True, help="LLMInferenceService / worker pod app name")
    parser.add_argument("--artifact-prefix", required=True, help="Artifact prefix under /results")
    parser.add_argument("--interval", type=int, default=20, help="Polling interval in seconds")
    parser.add_argument("--once", action="store_true", help="Print one snapshot and exit")
    args = parser.parse_args()

    try:
        while True:
            try:
                print(summarize(args.namespace, args.job, args.service, args.artifact_prefix), flush=True)
            except Exception as exc:  # keep the monitor alive across intermittent API failures
                print(f"[{now_utc()}] monitor-error: {exc}", file=sys.stderr, flush=True)
            if args.once:
                return 0
            time.sleep(args.interval)
    except KeyboardInterrupt:
        return 130


if __name__ == "__main__":
    raise SystemExit(main())
