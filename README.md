# mipit-infra

Infraestructura de despliegue reproducible para **MiPIT PoC** — un middleware de pagos interoperables entre rieles PIX (Brasil) y SPEI (México).

Este repositorio contiene Docker Compose, configuración de red, `.env` templates, scripts de arranque/limpieza, seeds de base de datos y configuración de Nginx reverse proxy.

## Servicios y puertos

| Servicio      | Puerto externo | Puerto interno | Exposición |
|---------------|---------------|---------------|------------|
| Nginx HTTPS   | 443           | 443           | Público    |
| Nginx HTTP    | 80            | 80            | Redirige   |
| Core API      | 8080          | 8080          | Interno    |
| UI            | 3001          | 3000          | Interno    |
| PostgreSQL    | 5432          | 5432          | Interno    |
| RabbitMQ AMQP | 5672          | 5672          | Interno    |
| RabbitMQ UI   | 15672         | 15672         | Demo       |
| Prometheus    | 9090          | 9090          | Demo       |
| Grafana       | 3000          | 3000          | Demo       |
| Jaeger UI     | 16686         | 16686         | Demo       |
| Jaeger OTLP   | 4318          | 4318          | Interno    |

## Requisitos previos

- Docker y Docker Compose v2+
- OpenSSL (para generar certificados TLS self-signed)
- Bash (los scripts usan `#!/bin/bash`)

## Inicio rápido

```bash
# Levantar todo (genera certs, copia .env, build & up)
bash scripts/up.sh

# Ver logs
bash scripts/logs.sh            # todos los servicios
bash scripts/logs.sh core       # solo el core

# Health check
bash scripts/health-check.sh

# Detener
bash scripts/down.sh

# Reset completo (elimina volúmenes y re-levanta)
bash scripts/reset.sh

# Re-ejecutar seeds de BD
bash scripts/seed.sh
```

## Estructura del repositorio

```
mipit-infra/
├── compose/          # Docker Compose (principal + overrides dev)
├── db/
│   ├── init/         # Schema SQL y seeds (ejecutados al init)
│   └── migrations/   # Migraciones futuras
├── rabbitmq/         # Config, definiciones y plugins
├── nginx/            # Reverse proxy config y certificados
├── scripts/          # Scripts de operación
├── env/              # Templates .env.example
└── docs/             # Documentación adicional
```

## Repositorios relacionados

| Repo | Descripción |
|------|------------|
| [mipit-core](https://github.com/MIPIT-PoC/mipit-core) | Motor del middleware |
| [mipit-adapter-pix](https://github.com/MIPIT-PoC/mipit-adapter-pix) | Adaptador PIX (Brasil) |
| [mipit-adapter-spei](https://github.com/MIPIT-PoC/mipit-adapter-spei) | Adaptador SPEI (México) |
| [mipit-ui](https://github.com/MIPIT-PoC/mipit-ui) | Dashboard Next.js |
| [mipit-observability](https://github.com/MIPIT-PoC/mipit-observability) | Prometheus, Grafana, Jaeger |
| [mipit-testkit](https://github.com/MIPIT-PoC/mipit-testkit) | Tests E2E y carga |
| [mipit-docs](https://github.com/MIPIT-PoC/mipit-docs) | Documentación del proyecto |
