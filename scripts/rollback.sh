#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# MiPIT PoC — Rollback Script
# Reverts to the previous Docker image tags.
# Usage: ./rollback.sh [sha-xxxxxxx]
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail
cd "$(dirname "$0")/../compose"

TARGET_SHA="${1:-}"
REGISTRY="${REGISTRY:-ghcr.io}"
IMAGE_PREFIX="${IMAGE_PREFIX:-ghcr.io/mipit-poc/mipit}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[rollback]${NC} $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
error() { echo -e "${RED}[error]${NC} $*" >&2; exit 1; }

SERVICES=(core adapter-pix adapter-spei ui)

if [ -z "$TARGET_SHA" ]; then
  warn "No se especificó SHA destino. Listando imágenes disponibles..."
  echo ""
  for svc in "${SERVICES[@]}"; do
    echo "  ${IMAGE_PREFIX}-${svc}:"
    docker images "${IMAGE_PREFIX}-${svc}" --format "    {{.Tag}} — {{.CreatedAt}}" | head -5
  done
  echo ""
  echo "Uso: $0 sha-abc1234"
  exit 0
fi

log "Iniciando rollback a: $TARGET_SHA"

# Verify target images exist
for svc in "${SERVICES[@]}"; do
  img="${IMAGE_PREFIX}-${svc}:${TARGET_SHA}"
  if ! docker image inspect "$img" &>/dev/null; then
    error "Imagen no encontrada: $img — ¿el SHA es correcto?"
  fi
done

log "Tomando snapshot del estado actual..."
docker compose ps > /tmp/mipit-pre-rollback-state.txt || true

log "Actualizando docker-compose.override.yml con SHA: $TARGET_SHA..."
cat > docker-compose.override.yml << EOF
# Rollback to: $TARGET_SHA
# Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)
services:
  core:
    image: ${IMAGE_PREFIX}-core:${TARGET_SHA}
  adapter-pix:
    image: ${IMAGE_PREFIX}-adapter-pix:${TARGET_SHA}
  adapter-spei:
    image: ${IMAGE_PREFIX}-adapter-spei:${TARGET_SHA}
  ui:
    image: ${IMAGE_PREFIX}-ui:${TARGET_SHA}
EOF

log "Reiniciando servicios con imágenes de rollback..."
docker compose up -d --no-build

log "Esperando que los servicios estén listos..."
sleep 10
bash "$(dirname "$0")/health-check.sh" || warn "Algunos servicios no respondieron — revisa los logs"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  ${GREEN}Rollback completado${NC} → $TARGET_SHA"
echo "  Para revertir el rollback: rm docker-compose.override.yml && docker compose up -d"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
