#!/bin/bash
set -euo pipefail

check_service() {
  local name=$1 url=$2
  if curl -sf -o /dev/null --max-time 5 "$url" 2>/dev/null; then
    echo "  ✓ $name"
  else
    echo "  ✗ $name (no responde en $url)"
  fi
}

echo "==> Health Check de servicios:"
check_service "PostgreSQL"  "localhost:5432"
check_service "RabbitMQ"    "http://localhost:15672"
check_service "Core API"    "http://localhost:8080/health"
check_service "UI"          "http://localhost:3001"
check_service "Prometheus"  "http://localhost:9090/-/healthy"
check_service "Grafana"     "http://localhost:3000/api/health"
check_service "Jaeger"      "http://localhost:16686"
