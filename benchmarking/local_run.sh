#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_URL="${TARGET_URL:-https://inference-gateway.apps.sovereign-ai-stack-cl02.ocp.speedcloud.co.in/vinod/qwen2-7b-instruct-nvidia}"
MODEL_NAME="${MODEL_NAME:-Qwen/Qwen2.5-7B-Instruct}"
OC_TOKEN="${OC_TOKEN:-$(oc whoami -t)}"
OUTPUT_DIR="${OUTPUT_DIR:-${SCRIPT_DIR}/results}"
RATES="${RATES:-1,2}"

mkdir -p "${OUTPUT_DIR}"

# Fail early if gateway auth is invalid/expired.
curl -k -fsS \
  -H "Authorization: Bearer ${OC_TOKEN}" \
  "${TARGET_URL}/v1/models" >/dev/null

guidellm benchmark run \
    --target "${TARGET_URL}" \
    --model "${MODEL_NAME}" \
    --processor "${MODEL_NAME}" \
    --data "prompt_tokens=512,output_tokens=128,samples=20" \
    --rate-type concurrent \
    --max-seconds 300 \
    --max-errors 200 \
    --rate "${RATES}" \
    --output-dir "${OUTPUT_DIR}" \
    --outputs benchmark-results.json,benchmark-results.html \
    --backend-kwargs "{\"api_key\": \"${OC_TOKEN}\", \"verify\": false, \"http2\": false, \"validate_backend\": false}"
