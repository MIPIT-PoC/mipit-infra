#!/usr/bin/env bash
# P09: Migration runner.
# Idempotent. Tracks applied versions in schema_migrations table.
# Usage:
#   bash scripts/migrate.sh                # default: against running mipit-postgres container
#   POSTGRES_CONTAINER=other bash ...      # override container name
set -euo pipefail

CONTAINER="${POSTGRES_CONTAINER:-mipit-postgres}"
DB_USER="${POSTGRES_USER:-mipit}"
DB_NAME="${POSTGRES_DB:-mipit}"
MIGRATIONS_DIR="$(cd "$(dirname "$0")/../db/migrations" && pwd)"

echo "==> Migration runner"
echo "    Container : $CONTAINER"
echo "    DB        : $DB_USER@$DB_NAME"
echo "    Dir       : $MIGRATIONS_DIR"

# 1. Ensure schema_migrations table exists
docker exec "$CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -q -c \
  "CREATE TABLE IF NOT EXISTS schema_migrations (version TEXT PRIMARY KEY, applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW());"

# 2. Apply each migration not yet applied, in lexicographic order
APPLIED_ANY=0
for file in $(ls -1 "$MIGRATIONS_DIR"/*.sql 2>/dev/null | sort); do
  version=$(basename "$file" .sql)
  already=$(docker exec "$CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -tAc \
    "SELECT 1 FROM schema_migrations WHERE version='$version'" 2>/dev/null || true)

  if [ -z "$already" ]; then
    echo "==> Applying $version ..."
    docker exec -i "$CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 < "$file"
    docker exec "$CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c \
      "INSERT INTO schema_migrations(version) VALUES ('$version') ON CONFLICT DO NOTHING" >/dev/null
    APPLIED_ANY=1
  else
    echo "    (already applied) $version"
  fi
done

if [ "$APPLIED_ANY" -eq 0 ]; then
  echo "==> Migrations up to date."
else
  echo "==> Migrations applied."
fi
