#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../compose"

echo "==> Generando certificados TLS (si no existen)..."
if [ ! -f ../nginx/certs/mipit.crt ]; then
  bash ../nginx/generate-certs.sh
fi

echo "==> Copiando .env.example -> .env (si no existen)..."
for f in ../env/*.env.example; do
  target="${f%.example}"
  [ -f "$target" ] || cp "$f" "$target"
done

echo "==> Levantando servicios..."
docker compose up -d --build

echo "==> Esperando health checks..."
sleep 5
bash ../scripts/health-check.sh

echo "==> MiPIT PoC listo!"
echo "    UI:       https://localhost"
echo "    API:      https://localhost/api/health"
echo "    Grafana:  http://localhost:3000"
echo "    RabbitMQ: http://localhost:15672"
echo "    Jaeger:   http://localhost:16686"
