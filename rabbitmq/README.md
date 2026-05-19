# RabbitMQ — topología MiPIT

## Audit 3 X2 — fuente de verdad de la topología

El archivo `definitions.json` es **documentación de referencia**, no se carga
en el broker. Los exchanges, queues y bindings reales los **declaran los
adapters y el core al startup** vía `assertExchange()` / `assertQueue()` /
`bindQueue()`:

| Componente | Archivo donde se declara la topología |
|---|---|
| Core (exchange `mipit.payments`, DLX, queue `payments.ack` + bindings) | `mipit-core/src/messaging/rabbitmq.ts` (canonical: `mipit-core/src/config/constants.ts`) |
| Adapter PIX (queue `payments.route.pix`) | `mipit-adapter-pix/src/messaging/consumer.ts` |
| Adapter SPEI (queue `payments.route.spei`) | `mipit-adapter-spei/src/messaging/consumer.ts` |
| Adapter BRE_B (queue `payments.route.breb`) | `mipit-adapter-breb/src/messaging/consumer.ts` |

## ¿Por qué no se carga `definitions.json`?

Históricamente `definitions.json` declaraba **configs distintas** a las que
los adapters asertaban (TTL/quorum/max-length divergentes). Si se cargara,
los adapters fallarían con `PRECONDITION_FAILED` al intentar redeclarar.

Decisión post Audit 3 X2:
- Los adapters quedan como **fuente de verdad** (porque tienen que
  declarar igualmente — RabbitMQ no garantiza que la topología existe).
- `definitions.json` queda como referencia visual del shape canónico
  para humanos.
- Si en futuro se quiere mover la SoT a `definitions.json`, hay que (a)
  agregar `management.load_definitions` en `rabbitmq.conf`, (b)
  sincronizar nombres con `mipit-core/src/config/constants.ts`, (c)
  cambiar los `assertQueue/Exchange` a `passive: true` para que el
  adapter falle ruidoso si la topología no existe (en lugar de
  declarar configs divergentes).

## Verificar topología en runtime

```bash
# Exchanges
curl -u mipit:mipit_secret http://localhost:15672/api/exchanges/mipit/mipit.payments | jq '.type,.arguments'

# Queues + bindings (deben aparecer ack.pix, ack.spei, ack.breb)
curl -u mipit:mipit_secret http://localhost:15672/api/queues/mipit/payments.ack/bindings | jq '.[].routing_key'
```

## Convención de nombres (canónica)

| Concepto | Nombre |
|---|---|
| Exchange principal | `mipit.payments` (topic, alternate=`mipit.unrouted`) |
| DLX | `mipit.dlx` (topic) |
| Unrouted fallback | `mipit.unrouted` (fanout) |
| Route keys | `route.pix`, `route.spei`, `route.breb` |
| Ack keys | `ack.pix`, `ack.spei`, `ack.breb` |
| DLQ key glob | `dlq.#` |
| Adapter queues | `payments.route.{pix,spei,breb}` |
| Core ack queue | `payments.ack` |
| DLQ (catch-all) | `payments.dlq` |
