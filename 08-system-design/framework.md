# 🏗️ System Design — Universal Framework

Use this skeleton for **every** system design question.

## 1. Clarify (5 min)
- Functional requirements — what must it do?
- Non-functional — scale, latency (p99), availability, consistency, durability, security, compliance.
- Out of scope — explicitly list.

## 2. Capacity Estimation (5 min)
- DAU / QPS (peak vs avg, ratio 2–5×).
- Read:write ratio.
- Storage/year (rows × bytes × retention).
- Bandwidth.

## 3. API Design (5 min)
- Public REST/gRPC contracts with method, path, request/response.
- Auth model.
- Idempotency / pagination / versioning.

## 4. Data Model (5 min)
- Entities + relationships.
- Choice: SQL vs NoSQL vs object store.
- Partition / shard key reasoning.
- Indexes.

## 5. High-Level Diagram (10 min)
- Client → CDN → API Gateway → Services → Data stores.
- Async flows: Kafka / SQS.
- Caches (Redis), search (OpenSearch), files (S3).

## 6. Deep Dive (15 min)
Pick 1–2 components and go deep:
- Hot-path read flow.
- Write/consistency flow.
- Failure handling.
- Race conditions / idempotency.
- LLD: classes, schema, sequence diagram.

## 7. Trade-offs (5 min)
- CAP positioning.
- Consistency model (strong vs eventual).
- Cost vs latency vs complexity.
- Build vs buy.

## 8. Cross-Cutting (5 min)
- Security (authn/z, encryption at rest/transit, secrets).
- Observability (logs, metrics, traces, SLOs).
- Deployment (multi-AZ, multi-region, blue-green).
- Cost.

## 9. Bonus
- ML / analytics path.
- Internationalization.
- Data retention / GDPR.

---

## Cheat Numbers (memorize)
- L1 cache: 0.5 ns • L2: 7 ns • RAM: 100 ns • SSD: 100 µs • Network round trip same DC: 0.5 ms • Cross-region: 50–150 ms.
- Single MySQL/PostgreSQL: ~5–10K writes/sec, 50K reads/sec on good hardware.
- Single Redis: 100K+ ops/sec.
- Kafka broker: ~100MB/s/disk; partition: ~10K msg/sec.
- 1 KB × 1M req/day ≈ 1 GB/day ≈ ~365 GB/year.