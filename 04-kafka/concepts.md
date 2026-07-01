# 📨 Kafka — Concepts

## Architecture
Producer → Broker (topic split into **partitions**, replicated across brokers) → Consumer Group (each partition consumed by exactly one consumer in the group).

- **Partition** = unit of parallelism + ordering.
- **Offset** = monotonic position per partition.
- **Replication factor** ≥ 3 in production.
- **ISR** (In-Sync Replicas) — replicas fully caught up.

## Ordering
Guaranteed **only within a partition**. Pick a meaningful key (`containerId`) so related events land together.

## Delivery Semantics
| Mode | Producer | Consumer |
|---|---|---|
| At-most-once | `acks=0`, no retries | commit before processing |
| At-least-once (default) | retries + `acks=1/all` | commit after processing |
| **Exactly-once** | `enable.idempotence=true` + transactions | `isolation.level=read_committed` |

## acks
- `0` — fire & forget (loss possible).
- `1` — leader ack (lost if leader fails before replication).
- `all` + `min.insync.replicas=2` — durable.

## Rebalance
Triggered by consumer join/leave or partition change. Avoid storms via:
- **Static membership**: `group.instance.id`
- **Cooperative-Sticky** assignor
- Tune `session.timeout.ms`, `max.poll.interval.ms`.

## Compaction vs Retention
- **Retention** — delete after time/size.
- **Compaction** — keep latest value per key (event sourcing, changelog topics).

## Schema Registry (Avro / Protobuf)
- **Backward compat** — new schema reads old data.
- **Forward** — old reader reads new data.
- **Full** — both.
- Add fields with defaults; never remove or rename.

## Outbox Pattern (atomic DB + event)
```
Tx { INSERT order; INSERT outbox(event); }
↓
Debezium (CDC) tails outbox → Kafka
↓
Mark/delete outbox row
```

## Poison Pill
Bad message that crashes consumer in a loop. Solution: catch deser/processing errors → publish to **DLQ topic** with metadata (error, original headers).

## Streams vs Consumer API
- **Consumer API** — low-level, stateless typically.
- **Kafka Streams** — DSL, joins, windows, aggregations, RocksDB state stores; exactly-once via transactions.

## Scaling
Max parallelism per group = number of partitions. Plan partition count up front (re-partitioning is painful).

## Replay
```
kafka-consumer-groups --bootstrap-server ... \
  --group fulfilment --topic order-events \
  --reset-offsets --to-datetime 2026-04-01T00:00:00.000 --execute
```
(Consumer must be stopped.)