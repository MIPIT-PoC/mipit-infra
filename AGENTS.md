# AGENTS.md

<purpose>
This repository contains the infrastructure layer for MiPIT-PoC: Docker Compose orchestration, PostgreSQL schema and seeds, RabbitMQ topology, Nginx reverse proxy with TLS, and operational scripts.

It is responsible for:
- defining and orchestrating all 12 services via Docker Compose,
- PostgreSQL DDL (5 tables: payments, audit_events, route_rules, mapping_table, idempotency_keys),
- seed data for route_rules (5 rules) and mapping_table (44 mappings),
- RabbitMQ exchanges, queues, bindings, and DLQ configuration,
- Nginx HTTPS termination and reverse proxy to core and UI,
- environment variable templates for all services,
- operational scripts (up, down, reset, health-check, seed, logs).

Treat shipped configuration as the primary source of truth.
When code and documents disagree, prefer:
1. current repo configuration files,
2. current architecture/design artifacts in mipit-docs,
3. current SRS,
4. project plan / older planning notes.
</purpose>

<project_scope>
This repo manages infrastructure configuration only.
It does NOT contain:
- application source code (that lives in mipit-core, mipit-adapter-*, mipit-ui),
- test suites (those live in mipit-testkit),
- observability configs (those live in mipit-observability),
- documentation prose (that lives in mipit-docs).

All services use Docker images built from their respective repos or official images.
Use only synthetic data and mock configurations suitable for the PoC.
</project_scope>

<instruction_priority>
- User instructions override default style, tone, and initiative preferences.
- Safety, honesty, privacy, and permission constraints do not yield.
- If a newer user instruction conflicts with an earlier one, follow the newer instruction.
- Preserve earlier instructions that do not conflict.
</instruction_priority>

<workflow>
  <phase name="clarify">
  - Before modifying infrastructure, clarify which services are affected and whether the change impacts networking, ports, volumes, or environment variables.
  - For schema changes, clarify impact on mipit-core persistence layer.
  - For RabbitMQ changes, clarify impact on mipit-core publisher/consumer and adapter workers.
  </phase>

  <phase name="research">
  - Inspect docker-compose.yml, .env templates, SQL files, and RabbitMQ definitions before proposing changes.
  - Verify port mappings, service names, network aliases, and health check configurations.
  - Cross-reference with mipit-core and adapter repos when changing shared contracts (DB schema, queue names, exchange topology).
  </phase>

  <phase name="plan">
  - Present a concrete plan covering: affected services, port/network changes, schema migrations, seed data updates, env var changes.
  - Wait for explicit user approval before modifying infrastructure files.
  </phase>

  <phase name="implement">
  - Keep docker-compose.yml clean and well-commented.
  - Use explicit health checks for all services.
  - Keep SQL migrations idempotent (IF NOT EXISTS, etc.).
  - Keep seed data realistic for the PoC demo.
  </phase>

  <phase name="verify">
  - After changes, verify with `docker compose up` that all services start.
  - Run health-check.sh to confirm connectivity.
  - Verify SQL schema with `\dt` and seed data with SELECT queries.
  - Verify RabbitMQ topology in management UI (port 15672).
  </phase>

  <phase name="document">
  - Update README.md when services, ports, or setup steps change.
  - Update docs/ports-and-services.md when adding/removing services.
  - Update env/*.env.example when environment variables change.
  </phase>
</workflow>

<architecture_rules>
- Docker Compose defines the canonical service topology for local development and demo.
- Service names in docker-compose.yml are the DNS hostnames used by application code.
- PostgreSQL schema is the source of truth for persistence contracts.
- RabbitMQ definitions.json is the source of truth for messaging topology.
- Nginx config is the source of truth for external-facing routing and TLS.
- Environment variable templates define the contract between infra and application services.
</architecture_rules>

<infra_rules>
- Keep all services in a single docker-compose.yml with optional override for dev.
- Use named volumes for data persistence (postgres_data, rabbitmq_data).
- Use a single Docker network (mipit-network) for inter-service communication.
- Keep health checks on all services for proper startup ordering.
- SQL files in db/init/ run in alphabetical order on first postgres start.
- RabbitMQ definitions.json is loaded via the management plugin on startup.
- Nginx certs are self-signed for PoC; generate-certs.sh creates them.
- Scripts in scripts/ should be idempotent and safe to re-run.
</infra_rules>

<testing_rules>
- Infrastructure changes should be verified by running the full stack.
- Use health-check.sh as a quick smoke test after changes.
- Verify seed data counts match expectations (5 route_rules, 44 mapping_table entries).
</testing_rules>

<default_commands>
- Start all services: `./scripts/up.sh` or `docker compose up -d --build`
- Stop all services: `./scripts/down.sh` or `docker compose down`
- Reset (destroy volumes): `./scripts/reset.sh` or `docker compose down -v`
- Health check: `./scripts/health-check.sh`
- View logs: `./scripts/logs.sh [service]`
- Re-run seeds: `./scripts/seed.sh`
- Generate TLS certs: `./nginx/generate-certs.sh`
</default_commands>
