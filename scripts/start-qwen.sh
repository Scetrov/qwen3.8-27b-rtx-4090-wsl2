#!/usr/bin/env bash
set -euo pipefail

exec ../llama.cpp/build/bin/llama-server \
  -hf unsloth/Qwen3.8-27B-GGUF:UD-Q4_K_XL \
  --alias qwen3.8-27b \
  --host 0.0.0.0 \
  --cors-origins http://10.229.2.10 \
  --port 9931 \
  --n-gpu-layers all \
  --parallel 1 \
  --ctx-size 65536 \
  --flash-attn on \
  --cache-type-k q8_0 \
  --cache-type-v q8_0 \
  --batch-size 2048 \
  --ubatch-size 512 \
  --spec-type draft-mtp \
  --spec-draft-n-max 2 \
  --jinja \
  --reasoning on \
  --reasoning-effort medium \
  --reasoning-preserve \
  --temp 1.0 \
  --top-p 0.95 \
  --top-k 20 \
  --min-p 0 \
  --presence-penalty 0 \
  --repeat-penalty 1.0 \
  --fit off \
  --image-min-tokens 1024 \
  --api-key-file ./secrets/llama-api-key.txt \
  --metrics
