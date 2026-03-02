#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../compose"

SERVICE="${1:-}"

if [ -n "$SERVICE" ]; then
  echo "==> Logs de $SERVICE:"
  docker compose logs -f "$SERVICE"
else
  echo "==> Logs de todos los servicios:"
  docker compose logs -f
fi
