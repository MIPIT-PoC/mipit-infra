#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# MiPIT PoC — VM Setup & Deploy Script
# Sets up a fresh Ubuntu 22.04 VM and deploys all MiPIT services.
# Usage: curl -sSL <url>/deploy-vm.sh | sudo bash
#        or: sudo bash deploy-vm.sh [--skip-docker]
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/mipit-poc/mipit}"
BRANCH="${BRANCH:-main}"
DEPLOY_DIR="${DEPLOY_DIR:-/opt/mipit}"
SKIP_DOCKER="${1:-}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[mipit]${NC} $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
error() { echo -e "${RED}[error]${NC} $*" >&2; exit 1; }

# ── Prerequisite checks ─────────────────────────────────────────────────────
[ "$(id -u)" = 0 ] || error "Este script debe ejecutarse como root (sudo)"
command -v curl >/dev/null || apt-get install -y curl
command -v git  >/dev/null || apt-get install -y git

log "MiPIT PoC — Configuración de VM"
log "Sistema: $(lsb_release -ds 2>/dev/null || uname -s)"

# ── Install Docker ────────────────────────────────────────────────────────
if [ "$SKIP_DOCKER" != "--skip-docker" ] && ! command -v docker &>/dev/null; then
  log "Instalando Docker Engine..."
  curl -fsSL https://get.docker.com | bash
  systemctl enable docker
  systemctl start docker
  log "Docker instalado: $(docker --version)"
else
  log "Docker ya instalado: $(docker --version)"
fi

# ── Install Docker Compose plugin ───────────────────────────────────────
if ! docker compose version &>/dev/null; then
  log "Instalando Docker Compose plugin..."
  apt-get install -y docker-compose-plugin
fi
log "Docker Compose: $(docker compose version)"

# ── Clone/update repository ─────────────────────────────────────────────
if [ -d "$DEPLOY_DIR/.git" ]; then
  log "Actualizando repositorio en $DEPLOY_DIR..."
  cd "$DEPLOY_DIR"
  git fetch origin
  git reset --hard "origin/$BRANCH"
else
  log "Clonando repositorio en $DEPLOY_DIR..."
  git clone --branch "$BRANCH" --depth 1 "$REPO_URL" "$DEPLOY_DIR"
  cd "$DEPLOY_DIR"
fi

# ── Configure environment files ─────────────────────────────────────────
log "Configurando archivos de entorno..."
cd "$DEPLOY_DIR/mipit-infra"
for f in env/*.env.example; do
  target="${f%.example}"
  if [ ! -f "$target" ]; then
    cp "$f" "$target"
    warn "Creado $target desde ejemplo — ¡revisa y actualiza los secretos!"
  fi
done

# ── Generate TLS certificates (self-signed for PoC) ────────────────────
if [ ! -f "$DEPLOY_DIR/mipit-infra/nginx/certs/mipit.crt" ]; then
  log "Generando certificados TLS auto-firmados..."
  mkdir -p "$DEPLOY_DIR/mipit-infra/nginx/certs"
  openssl req -x509 -newkey rsa:4096 -keyout "$DEPLOY_DIR/mipit-infra/nginx/certs/mipit.key" \
    -out "$DEPLOY_DIR/mipit-infra/nginx/certs/mipit.crt" \
    -days 365 -nodes \
    -subj "/C=MX/ST=CDMX/O=MiPIT PoC/CN=mipit.local"
  log "Certificados generados"
fi

# ── Pull latest Docker images ───────────────────────────────────────────
log "Descargando imágenes Docker más recientes..."
cd "$DEPLOY_DIR/mipit-infra/compose"
docker compose pull --ignore-pull-failures || warn "Algunas imágenes no pudieron descargarse, se usarán las locales o se construirán"

# ── Deploy ──────────────────────────────────────────────────────────────
log "Desplegando todos los servicios..."
docker compose up -d --build --remove-orphans

# ── Wait for services ───────────────────────────────────────────────────
log "Esperando que los servicios estén listos..."
sleep 10
bash "$DEPLOY_DIR/mipit-infra/scripts/health-check.sh" || warn "Algunos servicios no respondieron a tiempo"

# ── Setup systemd service (optional) ───────────────────────────────────
if command -v systemctl &>/dev/null; then
  log "Configurando servicio systemd para auto-inicio..."
  cat > /etc/systemd/system/mipit.service << 'EOF'
[Unit]
Description=MiPIT PoC — Middleware de Integración de Pagos Internacionales
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/mipit/mipit-infra/compose
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=180

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable mipit
  log "Servicio systemd configurado: systemctl {start,stop,status} mipit"
fi

# ── Summary ─────────────────────────────────────────────────────────────
HOST_IP=$(hostname -I | awk '{print $1}')
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  MiPIT PoC desplegado exitosamente"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  UI:          https://$HOST_IP"
echo "  API:         https://$HOST_IP/api/health"
echo "  Grafana:     http://$HOST_IP:3000  (admin / mipit2026)"
echo "  RabbitMQ:    http://$HOST_IP:15672 (mipit / mipit2026)"
echo "  Jaeger:      http://$HOST_IP:16686"
echo "  Prometheus:  http://$HOST_IP:9090"
echo ""
echo "  Traducciones: https://$HOST_IP/api/translate/rails"
echo ""
echo "  Para ver logs: cd $DEPLOY_DIR/mipit-infra && bash scripts/logs.sh"
echo "  Para detener:  cd $DEPLOY_DIR/mipit-infra && bash scripts/down.sh"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
