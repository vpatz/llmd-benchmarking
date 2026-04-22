# GuideLLM benchmarking — smoke tests

Runs **ordered checks** so you can eliminate failure classes one at a time (egress → API → completions).

## Phases

| ID | What it proves | If it fails, suspect |
|----|----------------|----------------------|
| **S01** | HTTPS GET to GitHub `raw.githubusercontent.com` (GuideLLM HTML template) | Cluster **egress / proxy / firewall**; HTML report step will fail |
| **S02** | HEAD to `huggingface.co` | **HF Hub** blocked; dataset/tokenizer download in Job may fail |
| **S03** | `SMOKE_TARGET` is set | Export target URL |
| **S04** | Target normalizes (GuideLLM strips `/v1`) | Malformed URL |
| **S05** | `GET {target}/health` (non-fatal if missing) | Optional; many stacks still work |
| **S06** | `GET {target}/v1/models` returns OpenAI-style JSON | Wrong base URL, path prefix, or **auth** |
| **S07** | `POST {target}/v1/chat/completions` returns `choices` | **Model id**, auth, timeouts, backend down |

## Quick start (external Route, e.g. laptop)

```bash
cd benchmarking/smoke
cp env.example smoke.env
# Edit smoke.env: set SMOKE_TARGET to your inference-gateway URL, SMOKE_API_KEY if required
set -a && source ./smoke.env && set +a
./run-all.sh
```

## Egress-only (no inference URL yet)

```bash
SMOKE_SKIP="S03 S04 S05 S06 S07" ./run-all.sh
```

## In-cluster target (internal Kubernetes DNS)

`run-all.sh` on your laptop **cannot** resolve `*.svc.cluster.local`. Run the same checks **from a pod** in the cluster:

```bash
oc run curl-smoke --rm -i --restart=Never -n vinod \
  --image=curlimages/curl:latest -- \
  curl -fsS "http://qwen2-7b-instruct-nvidia-epp-service.vinod.svc.cluster.local:9002/v1/models"
```

Mount or paste `run-all.sh` via ConfigMap, or copy the **S06/S07** curl commands with your internal `SMOKE_TARGET`.

## Align with `guidellm-job.yaml`

Use the **same** base URL, model name, `SMOKE_API_KEY` (or empty if no auth), and `SMOKE_INSECURE=1` for private ingress CA as in your Job / gateway docs.
