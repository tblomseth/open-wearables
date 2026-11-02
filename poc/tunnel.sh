#!/usr/bin/env bash
# Forward the frontend (3000), the API (8000) and Flower (5555) from the deploy host to localhost.
# Keep this running while you use the frontend or connect a provider with OAuth.
set -euo pipefail
HOST="${DEPLOY_HOST:-mini.local}"
echo "Tunnel to $HOST: http://localhost:3000 (frontend), http://localhost:8000 (API), http://localhost:5555 (Flower). Ctrl-C to stop."
exec ssh -N -o ExitOnForwardFailure=yes \
  -L 3000:127.0.0.1:3000 \
  -L 8000:127.0.0.1:8000 \
  -L 5555:127.0.0.1:5555 \
  "$HOST"
