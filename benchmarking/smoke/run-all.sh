#!/usr/bin/env bash
#
# Ordered smoke tests to isolate GuideLLM benchmarking failures (zeros, empty HTML).
# Run from a machine that can reach the URLs you configure (laptop = external target;
# for in-cluster DNS use: oc run ... curlimages/curl --rm -it --restart=Never -- curl ...)
#
#   cd benchmarking/smoke
#   cp env.example smoke.env   # edit SMOKE_TARGET etc.
#   set -a; source ./smoke.env; set +a
#   ./run-all.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

should_run() {
  local id="$1"
  for s in ${SMOKE_SKIP:-}; do
    [[ "$s" == "$id" ]] && return 1
  done
  return 0
}

run_phase() {
  local id="$1" name="$2"
  shift 2
  echo ""
  echo "======== ${id} — ${name} ========"
  if ! should_run "$id"; then
    warn "Skipped (${id} in SMOKE_SKIP)"
    return 0
  fi
  if "$@"; then
    pass "${id} complete"
  else
    fail "${id} failed — fix this before later phases (or set SMOKE_SKIP=${id} to continue)"
    exit 1
  fi
}

# --- S01: Egress to GitHub (HTML template fetch — same class of failure as GuideLLM HTML finalize) ---
phase_s01() {
  local url="${SMOKE_GUIDELLM_UI_URL:-https://raw.githubusercontent.com/vllm-project/guidellm/refs/heads/gh-pages/ui/v0.5.4/index.html}"
  curl -fsSL --max-time 20 -o /dev/null "$url"
}

# --- S02: Egress to Hugging Face (dataset + tokenizer downloads in Job) ---
phase_s02() {
  local code hf="${SMOKE_HF_URL:-https://huggingface.co}"
  code="$(curl -sS -o /dev/null -w "%{http_code}" -I --max-time 20 "$hf" || true)"
  [[ "$code" == "200" || "$code" == "301" || "$code" == "302" || "$code" == "307" ]]
}

# --- S03: TARGET is set when running inference phases ---
phase_s03() {
  [[ -n "${SMOKE_TARGET:-}" ]]
}

# --- S04: Base URL parses ---
phase_s04() {
  local base
  base="$(normalize_target "${SMOKE_TARGET}")"
  [[ -n "$base" ]]
  info "Normalized base: $base"
}

# --- S05: GET /health (optional — many stacks expose it) ---
phase_s05() {
  local base code
  base="$(normalize_target "${SMOKE_TARGET}")"
  code="$(curl -sS -o /dev/null -w "%{http_code}" ${SMOKE_INSECURE:+-k} --max-time "${SMOKE_CURL_TIMEOUT:-20}" "${base}/health" || true)"
  if [[ "$code" == "200" ]]; then
    pass "/health returned 200"
    return 0
  fi
  warn "/health returned HTTP ${code:-000} — continuing (some gateways omit /health)"
  return 0
}

# --- S06: GET /v1/models ---
phase_s06() {
  local base out
  base="$(normalize_target "${SMOKE_TARGET}")"
  local auth=()
  if [[ -n "${SMOKE_API_KEY:-}" ]]; then
    auth=(-H "Authorization: Bearer ${SMOKE_API_KEY}")
  fi
  out="$(curl -fsS ${SMOKE_INSECURE:+-k} --max-time "${SMOKE_CURL_TIMEOUT:-20}" "${auth[@]}" "${base}/v1/models")"
  if ! echo "$out" | grep -q '"data"'; then
    fail "/v1/models response missing expected JSON shape"
    return 1
  fi
  if ! echo "$out" | grep -Fq "${SMOKE_MODEL}"; then
    warn "Model id '${SMOKE_MODEL}' not found in /v1/models listing — completions may still work if name differs"
  fi
  return 0
}

# --- S07: POST /v1/chat/completions (minimal) ---
phase_s07() {
  local base body
  base="$(normalize_target "${SMOKE_TARGET}")"
  body="$(printf '%s' "{\"model\":\"${SMOKE_MODEL}\",\"messages\":[{\"role\":\"user\",\"content\":\"ping\"}],\"max_tokens\":8}")"
  local auth=()
  if [[ -n "${SMOKE_API_KEY:-}" ]]; then
    auth=(-H "Authorization: Bearer ${SMOKE_API_KEY}")
  fi
  local resp
  resp="$(curl -fsS ${SMOKE_INSECURE:+-k} --max-time "${SMOKE_CURL_TIMEOUT:-120}" \
    -H "Content-Type: application/json" \
    "${auth[@]}" \
    -d "$body" \
    "${base}/v1/chat/completions")" || return 1
  if ! echo "$resp" | grep -q '"choices"'; then
    fail "chat completion response missing choices (body may be error HTML/JSON)"
    echo "$resp" | head -c 800 >&2
    return 1
  fi
  return 0
}

main() {
  info "SMOKE_SKIP=${SMOKE_SKIP:-<empty>}"
  run_phase S01 "Egress: GitHub raw (GuideLLM HTML template URL)" phase_s01
  run_phase S02 "Egress: Hugging Face (Hub)" phase_s02
  run_phase S03 "Config: SMOKE_TARGET is set" phase_s03
  run_phase S04 "Config: normalize target URL" phase_s04
  run_phase S05 "Inference: GET /health (best effort)" phase_s05
  run_phase S06 "Inference: GET /v1/models" phase_s06
  run_phase S07 "Inference: POST /v1/chat/completions (smoke)" phase_s07
  echo ""
  pass "All executed phases succeeded. Safe to run GuideLLM benchmark Job with matching target + auth."
}

main "$@"
