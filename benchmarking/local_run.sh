#!/bin/bash

guidellm benchmark run \
    --target https://inference-gateway.apps.sovereign-ai-stack-cl02.ocp.speedcloud.co.in/vinod/qwen2-7b-instruct-nvidia \
    --model Qwen/Qwen2.5-7B-Instruct \
    --processor Qwen/Qwen2.5-7B-Instruct \
    --data garage-bAInd/Open-Platypus  \
    --rate-type concurrent \
    --max-seconds 300 \
    --rate 1,2,4 \
    --output-dir ./results \
    --outputs benchmark-results.json,benchmark-results.html \
    --backend-kwargs '{"api_key": "sha256~sLJcnsdagHY8_iSr7whZqO8w3U7QsMZJq7TpdqsQx3g", "validate_backend": false}'