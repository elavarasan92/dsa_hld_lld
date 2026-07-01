# 💰 System Design — Pricing / Rate Engine

## 1. Requirements
- Compute freight quote: base rate + surcharges (BAF, CAF, peak season, port, hazmat) + discounts (contract).
- Inputs: origin, destination, container type, weight, hazmat flag, customer tier, sailing date.
- p99 < 100 ms for quote.
- 10K quote requests/sec at peak.
- Rules change daily; must support hot reload.
- Audit each quote (regulatory).

## 2. APIs
```
POST /v1/quotes
{
  "customerId": "...",
  "origin": "INMAA", "destination": "DEHAM",
  "containerType": "40HC", "weight": 22000,
  "hazmat": false, "sailingDate": "2026-06-01"
}
→ { quoteId, totalUsd, breakdown[], validUntil }
```

## 3. HLD
```
API Gateway → Quote Service (Spring Boot, stateless)
                ├─ Rule Engine (Drools / custom DSL)
                ├─ Reference Data Cache (Redis):
                │     • lane base rates
                │     • surcharges (BAF, CAF)
                │     • customer contracts
                ├─ Cassandra/PostgreSQL (rule + rate tables)
                └─ Kafka topic: quote-issued (audit + analytics)

Rate-Admin Service (back-office) → publishes rule updates to Kafka:
  → Quote Service consumes → invalidates Redis keys → reloads.
```

## 4. Caching Strategy
- L1: in-process Caffeine (1 min, hot rules).
- L2: Redis (10 min, all rules).
- Cache key: `(origin,dest,containerType,date-bucket)`.
- Invalidation: pub/sub from Rate-Admin → Redis `DEL`.

## 5. Rule Engine
- Drools for complex rules (decision tables loadable by business users).
- Or simple JSON rules + Java evaluator if rules are stable.
- Rules versioned; effective `from`/`to` dates.

## 6. Quote Lifecycle
1. Compute quote → store in PostgreSQL `quote(id, breakdown jsonb, valid_until, version)`.
2. Quote valid for 24h.
3. On booking, re-validate quote (rate not changed since validity).

## 7. Failure Handling
- If Redis down → fallback to DB (slower).
- If rule engine throws → return last good cached quote with warning header.
- All quote computations idempotent (same inputs → same output) given same rule version.

## 8. Observability
- Histogram of quote latency.
- Counter of cache hit/miss.
- Per-lane volume.
- Audit topic consumed by analytics (BigQuery / Snowflake).

## 9. Trade-offs
- Drools (powerful, complex) vs custom DSL (simple, limited).
- Pre-compute popular lanes nightly into Redis vs on-demand.
- Strong vs eventual consistency on rule reload (eventual; document staleness window).