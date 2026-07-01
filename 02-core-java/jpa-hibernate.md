# 🗃️ JPA / Hibernate

## EntityManager vs SessionFactory
- `EntityManager` — JPA standard, per-transaction, not thread-safe.
- `SessionFactory` — Hibernate, app-wide, thread-safe, expensive to create.

## N+1 Problem
Lazy collection → 1 parent query + N child queries. Fixes:
```java
// JOIN FETCH
@Query("select b from Booking b join fetch b.containers where b.id = :id")
// EntityGraph
@EntityGraph(attributePaths = {"containers"})
List<Booking> findAll();
// Batch fetching
@BatchSize(size = 25) @OneToMany ...
// DTO projection (best for read-only)
select new com.hl.dto.BookingDTO(b.id, c.code) from Booking b join b.containers c
```

## Caches
- **L1** — per `EntityManager`, mandatory.
- **L2** — `SessionFactory`-wide (EhCache, Hazelcast, Redis), opt-in via `@Cacheable`. Use for read-mostly entities.
- **Query cache** — `@org.hibernate.annotations.QueryCache`, requires L2.

## @Transactional propagation
| Value | Behavior |
|---|---|
| `REQUIRED` (default) | join existing or create new |
| `REQUIRES_NEW` | suspend current, start new |
| `NESTED` | savepoint within parent |
| `MANDATORY` | must run in existing |
| `SUPPORTS` | join if exists, else none |
| `NOT_SUPPORTED` | suspend if exists |
| `NEVER` | fail if exists |

⚠ **Self-invocation pitfall**: calling `@Transactional` method via `this.` bypasses Spring proxy → no transaction. Fix: inject self / move to another bean / `@EnableAspectJAutoProxy(proxyTargetClass=true)` not enough alone.

## Locking
- **Optimistic** (`@Version`) — no DB lock; throws `OptimisticLockException`. Low contention.
- **Pessimistic** — `LockModeType.PESSIMISTIC_WRITE` → `SELECT … FOR UPDATE`. High contention, hot rows.

## Lifecycle
Transient → Persistent → Detached → Removed.
- `persist()` — transient → persistent (void).
- `merge()` — copies detached state into managed; returns managed instance.
- `save()` (Hibernate) — assigns id, returns it.
- `flush()` — sync to DB. `clear()` — detach all.

## Bulk Operations
```java
@Modifying @Query("update Container c set c.status='IDLE' where c.lastSeen < :t")
int markIdle(@Param("t") Instant t);
```
- `hibernate.jdbc.batch_size=50`
- Batch insert pattern: every 50 → `em.flush(); em.clear();`
- Beware L1 cache bloat in long batches.

## Common Anti-patterns
- `@OneToMany(fetch=EAGER)` — almost always wrong.
- `OpenSessionInView` — hides N+1, leaks tx scope.
- Calling repository in a stream lambda → N+1.
- Storing huge BLOBs as entity fields — use S3 + pointer.