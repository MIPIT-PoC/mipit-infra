#!/bin/bash
# Audit 3 B3-003 — rewritten so the script does NOT lie:
#   - PostgreSQL is checked via `pg_isready` (not HTTP — the previous
#     curl on :5432 always failed).
#   - RabbitMQ broker check uses the Mgmt API root + creds.
#   - Adapter metrics endpoints (9101/9102/9103) verified.
#   - AlertManager (Wave 4 P07) added.
#   - Mocks (PIX/SPEI/BREB) added — they're the actual rail simulators.
set -uo pipefail

PASS=0; FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS+1)); }
fail() { echo "  ✗ $1 ($2)"; FAIL=$((FAIL+1)); }

check_http() {
  local name=$1 url=$2 extra=${3:-}
  if curl -sf -o /dev/null --max-time 5 $extra "$url" 2>/dev/null; then ok "$name"; else fail "$name" "$url"; fi
}

check_postgres() {
  # If pg_isready is available locally use it; otherwise rely on docker exec.
  if command -v pg_isready >/dev/null 2>&1; then
    if pg_isready -h localhost -p 5432 -U mipit -d mipit -t 3 >/dev/null 2>&1; then ok "PostgreSQL"; return; fi
  fi
  if docker exec mipit-postgres pg_isready -U mipit -d mipit >/dev/null 2>&1; then
    ok "PostgreSQL (via docker exec)"
  else
    fail "PostgreSQL" "pg_isready failed"
  fi
}

check_rabbitmq() {
  local user=${RABBITMQ_DEFAULT_USER:-mipit}
  local pwd=${RABBITMQ_DEFAULT_PASS:-mipit_secret}
  if curl -sf -u "$user:$pwd" -o /dev/null --max-time 5 "http://localhost:15672/api/overview" 2>/dev/null; then
    ok "RabbitMQ (Mgmt API auth OK)"
  else
    fail "RabbitMQ" "Mgmt API /api/overview rejected"
  fi
}

echo "==> Health Check de servicios MIPIT:"
echo ""
echo "  Infraestructura"
check_postgres
check_rabbitmq
check_http "Jaeger"       "http://localhost:16686"
check_http "Prometheus"   "http://localhost:9090/-/healthy"
check_http "AlertManager" "http://localhost:9093/api/v2/status"   # Wave 4 P07
check_http "Grafana"      "http://localhost:3000/api/health"

echo ""
echo "  Servicios MIPIT"
check_http "Core API"        "http://localhost:8080/health"
check_http "UI"              "http://localhost:3001"

echo ""
echo "  Adapters (métricas Prometheus :9101/9102/9103)"
check_http "Adapter PIX"     "http://localhost:9101/metrics"
check_http "Adapter SPEI"    "http://localhost:9102/metrics"
check_http "Adapter BRE_B"   "http://localhost:9103/metrics"

echo ""
echo "  Mocks (los rieles simulados — embebidos en cada adapter)"
# Adapter mock servers run in the same Node process as the adapter worker
# and listen on 9001/9002/9003 (NOT 7xxx). Compose port mappings:
#   adapter-pix:  9001 (mock) + 9101 (prom metrics)
#   adapter-spei: 9002 (mock) + 9102 (prom metrics)
#   adapter-breb: 9003 (mock) + 9103 (prom metrics)
check_http "Mock PIX"        "http://localhost:9001/health"
check_http "Mock SPEI"       "http://localhost:9002/health"
check_http "Mock BRE_B"      "http://localhost:9003/health"

echo ""
printf "==> Resumen: \033[32m%d OK\033[0m / \033[31m%d FAIL\033[0m\n" "$PASS" "$FAIL"
[ "$FAIL" -gt 0 ] && exit 1
exit 0
