#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

if ! command -v cloudflared >/dev/null 2>&1; then
  echo "Install cloudflared in WSL; see README.md." >&2
  exit 1
fi

if [[ ! -r secrets/cloudflare-tunnel-token.txt || ! -s secrets/cloudflare-tunnel-token.txt ]]; then
  echo "Save your Tunnel token in secrets/cloudflare-tunnel-token.txt; see README.md." >&2
  exit 1
fi

exec cloudflared tunnel --no-autoupdate --metrics 127.0.0.1:60123 run \
  --token-file ./secrets/cloudflare-tunnel-token.txt
