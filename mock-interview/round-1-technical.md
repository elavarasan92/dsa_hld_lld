# 🎙️ Mock Interview — Round 1: Technical Deep Dive

> Set timer to **45 min**. Answer aloud or in writing. Then read the model answers below.

## Questions
1. We have a Spring Boot service with `@Transactional` calling another `@Transactional` method **in the same class**. Does the inner one start a new transaction? Why or why not?
2. PostgreSQL queries on a 200M-row `container_history` table got slow. Walk through diagnosis and fixes.
3. Producer sends to Kafka; consumer processes the message and updates DB. Power fails between Kafka commit and DB commit. How do you make this exactly-once end-to-end?
4. Difference between `CompletableFuture.thenApply` and `thenCompose`? Give an example where the wrong one causes a bug.
5. You see `OutOfMemoryError: Metaspace`. Likely cause and fix?
6. Two microservices need consistent data: `Booking` creates a booking, `Inventory` must reserve a container. How do you guarantee consistency without 2PC?
7. REST endpoint `POST /bookings` — client retries on timeout, ends up with duplicate bookings. Fix?
8. ECS Fargate vs EKS — when do you choose which?
9. Your team's PR cycle time has crept up to 4 days. As a Principal, what do you do?
10. Java 21 virtual threads — when would you NOT use them?

---

## Model Answers

**1.** Self-invocation bypasses the Spring proxy → no new transaction, propagation annotation is ignored. Fixes: (a) inject self via `@Autowired private MyService self;` (b) move method to another bean (c) use AspectJ weaving.

**2.** `EXPLAIN (ANALYZE, BUFFERS)` to find Seq Scans. Confirm partitioning by `ts` (range, monthly). Add BRIN index on `ts`, B-tree on `(container_id, ts DESC)`. Check `pg_stat_user_tables` for missing indexes & dead tuples. Run `ANALYZE`. Tune `work_mem`. If still slow, archive cold data to S3 + Athena.

**3.** Use **outbox pattern**: producer writes business row + event in same DB tx. CDC ships to Kafka. Consumer is **idempotent** (dedup table keyed by event id). Combine with Kafka transactions if reading from Kafka and writing back. End-to-end EOS = idempotent producer + transactional read-process-write + idempotent consumer.

**4.** `thenApply(Function<T,R>)` — sync transform, returns `CF<R>`. `thenCompose(Function<T, CF<R>>)` — flatMap, avoids `CF<CF<R>>`. Bug: `cf.thenApply(id -> loadOrders(id))` — if `loadOrders` returns `CF<List>`, you get `CF<CF<List>>` and downstream code blocks unexpectedly. Fix: `thenCompose`.

**5.** Class-loader leak — typically hot redeploys, dynamic proxies (CGLIB), or libraries creating loaders per call. Diagnose with `jcmd <pid> GC.class_histogram` + heap dump → MAT → look for duplicate class loaders. Quick fix: bump `-XX:MaxMetaspaceSize`. Real fix: kill the leak (close loaders, reuse proxies).

**6.** **Saga**: Booking emits `BookingCreated` → Inventory consumes → reserves container → emits `ContainerReserved`. Booking advances state. On failure, Inventory emits `ReservationFailed` → Booking compensates (cancel). Combine with **outbox** for atomic DB+event. No 2PC needed.

**7.** Idempotency. Client sends `Idempotency-Key: <uuid>` header. Server stores `(key, response)` for 24h. Duplicate request returns cached response without re-executing. Use unique constraint on key in DB. Optionally also ensure business-level idempotency (e.g., `(customerId, externalRef)` unique).

**8.** **ECS Fargate** — AWS-only, simple, no node mgmt, fast to start, ideal for small/medium teams. **EKS** — Kubernetes portability (multi-cloud, on-prem), richer ecosystem (operators, Helm), but more ops. Choose EKS if you have K8s expertise or multi-cloud strategy; ECS if AWS-only and want simplicity.

**9.** Diagnose first: measure where time goes (waiting for review, waiting for CI, rework). Common fixes: (a) PR size limits (≤400 lines), (b) review SLA (within 24h, rotated), (c) faster CI (parallel, cached), (d) automated checks (lint, format) so reviews focus on logic, (e) trunk-based dev with feature flags. Track cycle-time metric weekly.

**10.** Don't use for: (a) CPU-bound work — no benefit, use platform threads + ForkJoinPool. (b) Code with `synchronized` blocks holding for long — pinning kills scaling; use `ReentrantLock`. (c) Code calling native via JNI that pins. (d) Heavy ThreadLocal use — each VT has its own, memory bloat.

---

## Self-Score Rubric (out of 10)
| Score | Meaning |
|---|---|
| 9–10 | Principal-level: trade-offs, alternatives, war stories |
| 7–8 | Senior: correct + reasonable depth |
| 5–6 | Mid-level: correct but shallow |
| <5 | Needs more prep |

Target average: **8+** for this role.