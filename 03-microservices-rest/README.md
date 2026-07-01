# 🧱 Microservices & REST

## Migration: Strangler Fig
Route slices of monolith traffic to new microservices via API gateway/proxy until monolith is empty. Migrate by **bounded context**, not by table.

## 12-Factor App
Codebase • Dependencies • Config (env) • Backing services • Build/Release/Run • Stateless processes • Port binding • Concurrency • Disposability • Dev/prod parity • Logs (stdout) • Admin processes.

## Service Discovery
- **Client-side**: Eureka, Ribbon.
- **Server-side**: AWS ELB, Cloud Map.
- **Kubernetes**: built-in DNS (`my-svc.namespace.svc.cluster.local`).

## API Gateway
Single entry: auth, rate limit, routing, aggregation, response shaping.
Options: Spring Cloud Gateway (reactive), Kong, AWS API Gateway.

## Resilience (Resilience4j)
| Pattern | Purpose |
|---|---|
| Circuit Breaker | open after N failures; half-open trial |
| Bulkhead | isolate thread pools per dependency |
| Retry | exponential backoff + jitter |
| TimeLimiter | bound latency |
| RateLimiter | protect downstream |

## Saga
- **Choreography** — services react to events. Decoupled, hard to trace.
- **Orchestration** — central coordinator (Camunda, Temporal). Visible flow, single point.

## Distributed Transactions
Avoid 2PC (blocking). Prefer:
- **Saga + compensating actions**
- **Outbox pattern** — write business row + event row in one DB tx; CDC (Debezium) ships events.

## Idempotency
Client sends `Idempotency-Key` header → server stores `(key, response)` for TTL → duplicate returns cached.

## REST best practices
- Plural nouns, hierarchical: `/bookings/{id}/containers`.
- Verbs via HTTP methods; statuses: 200, 201, 204, 400, 401, 403, 404, 409, 422, 429, 500.
- Pagination: cursor (`?cursor=…&limit=50`) > offset for large sets.
- Versioning: URI (`/v1/...`) simplest; header (`Accept: application/vnd.hl.v2+json`) cleaner.
- HATEOAS for L3 maturity (rarely worth it in practice).

## Backward compatibility
- Additive changes only.
- Never remove fields; deprecate with `Sunset` header.
- Consumer-driven contracts via **Pact**.
- Schema registry (Avro) backward-compatible by default.

## Observability
- **Logs** — structured JSON, correlation id.
- **Metrics** — RED (Rate, Errors, Duration) + USE (Utilization, Saturation, Errors).
- **Traces** — OpenTelemetry → Jaeger / X-Ray; propagate W3C Trace Context.

## Security
- OAuth2 / OIDC; JWT (short-lived) + refresh tokens.
- mTLS between services in mesh (Istio, Linkerd).
- Secrets in Vault / AWS Secrets Manager.
- OWASP API Top-10 awareness.