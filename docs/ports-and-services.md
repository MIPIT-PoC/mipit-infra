# Puertos y servicios — MiPIT PoC

Referencia completa de todos los servicios orquestados por `docker-compose.yml`.

## Tabla de puertos

| Servicio      | Imagen                                  | Puerto externo | Puerto interno | Red             | Exposición | Notas                         |
|---------------|-----------------------------------------|---------------|---------------|-----------------|------------|-------------------------------|
| Nginx HTTPS   | `nginx:1.25-alpine`                     | 443           | 443           | mipit-internal  | Público    | Reverse proxy con TLS         |
| Nginx HTTP    | `nginx:1.25-alpine`                     | 80            | 80            | mipit-internal  | Público    | Redirige a HTTPS              |
| Core API      | `ghcr.io/mipit-poc/mipit-core`          | 8080          | 8080          | mipit-internal  | Interno    | Motor del middleware          |
| UI            | `ghcr.io/mipit-poc/mipit-ui`            | 3001          | 3000          | mipit-internal  | Interno    | Dashboard Next.js             |
| Adapter PIX   | `ghcr.io/mipit-poc/mipit-adapter-pix`   | —             | —             | mipit-internal  | Interno    | Consume cola RabbitMQ         |
| Adapter SPEI  | `ghcr.io/mipit-poc/mipit-adapter-spei`  | —             | —             | mipit-internal  | Interno    | Consume cola RabbitMQ         |
| PostgreSQL    | `postgres:16-alpine`                    | 5432          | 5432          | mipit-internal  | Interno    | BD principal                  |
| RabbitMQ AMQP | `rabbitmq:3.13-management-alpine`       | 5672          | 5672          | mipit-internal  | Interno    | Mensajería async              |
| RabbitMQ UI   | `rabbitmq:3.13-management-alpine`       | 15672         | 15672         | mipit-internal  | Demo       | Consola de administración     |
| Prometheus    | `prom/prometheus:v2.51.0`               | 9090          | 9090          | mipit-internal  | Demo       | Métricas                      |
| Grafana       | `grafana/grafana:11.0.0`                | 3000          | 3000          | mipit-internal  | Demo       | Dashboards (admin/mipit2026)  |
| Jaeger UI     | `jaegertracing/all-in-one:1.56`         | 16686         | 16686         | mipit-internal  | Demo       | Trazas distribuidas           |
| Jaeger OTLP   | `jaegertracing/all-in-one:1.56`         | 4318          | 4318          | mipit-internal  | Interno    | Receptor OpenTelemetry        |

## Dependencias entre servicios

```
nginx ──► core ──► postgres
  │         │──► rabbitmq
  │
  └──► ui ──► core

adapter-pix  ──► rabbitmq
adapter-spei ──► rabbitmq

prometheus (independiente, scrape a core)
grafana    (independiente, lee de prometheus)
jaeger     (independiente, recibe traces OTLP)
```

## Volúmenes persistentes

| Volumen           | Servicio   | Ruta del contenedor              |
|-------------------|------------|----------------------------------|
| `postgres-data`   | PostgreSQL | `/var/lib/postgresql/data`       |
| `rabbitmq-data`   | RabbitMQ   | `/var/lib/rabbitmq`              |
| `grafana-data`    | Grafana    | `/var/lib/grafana`               |
| `prometheus-data` | Prometheus | `/prometheus`                    |

## RabbitMQ — Exchanges, colas y bindings

| Exchange          | Tipo  | Cola destino           | Routing key  |
|-------------------|-------|------------------------|--------------|
| `mipit.payments`  | topic | `payments.route.pix`   | `route.pix`  |
| `mipit.payments`  | topic | `payments.route.spei`  | `route.spei` |
| `mipit.payments`  | topic | `payments.ack`         | `ack.#`      |
| `mipit.dlx`       | topic | `dlq.pix`              | `dlq.pix`    |
| `mipit.dlx`       | topic | `dlq.spei`             | `dlq.spei`   |
