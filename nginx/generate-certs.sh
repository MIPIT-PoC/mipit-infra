#!/bin/bash
set -euo pipefail

CERT_DIR="$(dirname "$0")/certs"
mkdir -p "$CERT_DIR"

openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout "$CERT_DIR/mipit.key" \
  -out "$CERT_DIR/mipit.crt" \
  -subj "/C=CO/ST=Bogota/L=Bogota/O=MIPIT-PoC/OU=Tesis/CN=mipit.local"

echo "Certificados generados en $CERT_DIR"
