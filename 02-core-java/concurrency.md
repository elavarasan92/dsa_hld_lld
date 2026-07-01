# ☕ Concurrency

## Runnable vs Callable vs CompletableFuture
- `Runnable` — no return, no checked exception.
- `Callable<V>` — returns V, throws checked.
- `CompletableFuture<V>` — async + composable, non-blocking pipelines.

## Executors
| Pool | When |
|---|---|
| `FixedThreadPool` | bounded threads, **unbounded queue** (OOM risk) |
| `CachedThreadPool` | bursty short tasks, unbounded threads |
| `SingleThreadExecutor` | serialized work |
| `ScheduledThreadPool` | timers / cron |
| `ForkJoinPool` | divide-and-conquer; backs parallel streams |
| **Custom `ThreadPoolExecutor`** | **production** — bounded queue + named threads + reject policy |

```java
new ThreadPoolExecutor(8, 32, 60, SECONDS,
    new ArrayBlockingQueue<>(500),
    new ThreadFactoryBuilder().setNameFormat("svc-%d").build(),
    new ThreadPoolExecutor.CallerRunsPolicy());
```

## ConcurrentHashMap
- Java 7: 16 segment locks.
- Java 8: bucket-level CAS + `synchronized` on first node, treeify ≥ 8 collisions.

## ReentrantLock vs synchronized
ReentrantLock adds: `tryLock(timeout)`, fairness, multiple `Condition`s, interruptible. Use when synchronized is insufficient.

## Singleton (thread-safe)
```java
public enum Singleton { INSTANCE; }                 // best
// Initialization-on-demand holder
class S { static class H { static final S I = new S(); } static S get(){ return H.I; } }
```

## Deadlock
4 conditions: mutual exclusion, hold-and-wait, no preemption, circular wait.
**Prevent**: consistent lock ordering • `tryLock` with timeout • lock-free structures.
**Detect**: `jstack` shows "Found one Java-level deadlock".

## CompletableFuture cheat-sheet
```java
CompletableFuture.supplyAsync(this::loadUser, exec)
  .thenApply(User::getId)                  // sync transform
  .thenCompose(id -> loadOrders(id))       // returns CF<List<Order>> (flatMap)
  .thenCombine(loadInventory(), (orders, inv) -> merge(orders, inv))
  .exceptionally(ex -> fallback())
  .orTimeout(2, SECONDS);
```

## Java 21 Virtual Threads
- Lightweight (M:N), great for **I/O-bound** code.
- **Don't** use for CPU-bound work, or with `synchronized` blocks (pinning) — use `ReentrantLock` instead.