#!/bin/bash
set -euo pipefail

echo "==> Re-ejecutando seeds en la base de datos..."

SCRIPT_DIR="$(dirname "$0")"
DB_DIR="$SCRIPT_DIR/../db/init"

docker exec -i mipit-postgres psql -U mipit -d mipit < "$DB_DIR/002_seed_route_rules.sql"
docker exec -i mipit-postgres psql -U mipit -d mipit < "$DB_DIR/003_seed_mapping_table.sql"

echo "==> Seeds aplicados correctamente"
