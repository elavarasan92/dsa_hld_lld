# 🚢 System Design — Container Tracking

## 1. Requirements
**Functional**
- Ingest GPS/IoT events from vessels & containers (lat, lon, temp, status).
- Real-time location lookup per container.
- History (last 1 year) with time-range queries.
- Geo-fencing alerts (e.g., entered restricted zone).
- ETA prediction.

**Non-Functional**
- 1M containers, ~10K events/sec peak (16K with bursts).
- p99 read < 200 ms.
- 99.95% availability.
- Multi-region DR.
- Eventually consistent OK for history; strong-recent for latest.

## 2. Capacity
- 10K events/sec × 200 B = **2 MB/s** ingest.
- 1 year history: 10K × 86400 × 365 × 200 B ≈ **63 TB** raw → compress (parquet) → ~15 TB.
- DynamoDB hot store: 1M items × 500 B = ~500 MB (fits in memory).

## 3. APIs
```
GET  /containers/{id}/location              → latest snapshot
GET  /containers/{id}/history?from=&to=     → paginated events
GET  /vessels/{id}/containers               → all containers on vessel
POST /containers/{id}/geofence              → register geofence
WS   /containers/{id}/stream                → live updates
```

## 4. Data Model

### Hot store — DynamoDB
```
ContainerSnapshot {
  PK: containerId,
  lat, lon, ts, status, vesselId, updatedAt
}
```
Conditional update: `if NewTs > existingTs` to ignore late events.

### Cold store — PostgreSQL (partitioned)
```sql
CREATE TABLE container_history (
  container_id TEXT NOT NULL,
  ts           TIMESTAMPTZ NOT NULL,
  lat          DOUBLE PRECISION,
  lon          DOUBLE PRECISION,
  status       TEXT,
  vessel_id    TEXT,
  PRIMARY KEY (container_id, ts)
) PARTITION BY RANGE (ts);
CREATE INDEX ON container_history USING BRIN (ts);
```
Monthly partitions; BRIN index = tiny + great for time-series.

### Analytics — S3 + Athena (parquet, hourly partitions).

## 5. HLD
```
IoT/Vessel → AWS IoT Core (MQTT/TLS)
            → Kafka (MSK): topic=container-events, key=containerId, 50 partitions
            → Stream Processor (Kafka Streams):
                 • enrich with vessel KTable
                 • validate (schema, freshness)
                 • branches:
                     ├─ DynamoDB writer (latest snapshot) ──────┐
                     ├─ PostgreSQL batch writer (500/commit)    │
                     ├─ S3 sink (parquet, hourly)               │
                     └─ Geo-fence processor → alert topic       │
                                              ↓                  │
                       Notification Service (SNS/SES/FCM)        │
                                                                 │
Read API (Spring Boot) ──────────────── reads ──────────────────┘
   • /location → DynamoDB (~5 ms)
   • /history  → PostgreSQL (partition pruning)
WebSocket Gateway tails alert topic + snapshot updates → push UI.
```

## 6. LLD highlights
- **Avro schema** registered in Schema Registry.
- **Idempotent consumer**: dedup by `(containerId, ts)`.
- **Late event handling**: conditional write keyed on `ts`.
- **Hot partition** (mega-vessel with 1000s of containers): sub-key by `containerId#hash%N`.
- **Backpressure**: Kafka holds the buffer; consumers scale via KEDA on lag.
- **Outbox** from booking service for status changes.

## 7. Failure Modes
| Failure | Mitigation |
|---|---|
| Broker AZ down | MSK multi-AZ replication, `min.insync.replicas=2` |
| Late/duplicate events | conditional write by `ts`, dedup table |
| Hot partition | sub-key hashing |
| DynamoDB throttle | exponential backoff + DLQ for write fails |
| Cross-region DR | MirrorMaker 2 → secondary region; Aurora global DB; DynamoDB global tables |
| IoT device offline | local buffering, replay on reconnect |

## 8. Observability
- OpenTelemetry across producer/streams/consumers.
- Metrics: ingest rate, consumer lag, write latency p50/p95/p99, geofence alert latency.
- Alerts: lag > 60 s, write error rate > 1%, hot partition skew.

## 9. Trade-offs
- Kafka Streams (in-JVM) vs Flink (richer windows, separate cluster) — chose Streams to reduce ops.
- DynamoDB vs Redis for hot — DynamoDB durable + auto-scales, Redis cheaper but ephemeral.
- ETA: simple linear vs ML — start linear, add ML model behind sidecar later.

## 10. Bonus
- **ML ETA**: features = past route, weather, port congestion → SageMaker model → API.
- **GDPR**: containerId is not PII; vessel telemetry retained per regulations.
- **Cost**: MSK ~$1k/mo for 3 brokers; DynamoDB on-demand ~$2k/mo; PostgreSQL Aurora ~$1.5k/mo.