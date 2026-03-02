#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../compose"
echo "==> Reset completo (eliminando volúmenes)..."
docker compose down -v
echo "==> Re-levantando..."
bash ../scripts/up.sh
