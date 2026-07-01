# ☕ JVM & Memory

## Memory Areas
| Area | Purpose | Notes |
|---|---|---|
| **Heap** | Objects (Young = Eden+S0+S1, Old) | GC managed |
| **Stack** | Per-thread frames, locals | StackOverflowError on overflow |
| **Metaspace** | Class metadata (Java 8+, native memory) | Replaced PermGen |
| **Code cache** | JIT-compiled native code | |
| **Native** | Direct buffers, threads | |

## Garbage Collectors
- **Parallel** — throughput, batch jobs.
- **G1** (default Java 9+) — region-based, predictable pauses (`-XX:MaxGCPauseMillis=200`). Good for microservices.
- **ZGC / Shenandoah** — sub-ms pauses, large heaps. Use for latency-critical.
- **Tuning starter (4G heap, microservice)**:
  `-Xms2g -Xmx2g -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+HeapDumpOnOutOfMemoryError`

## Reference Types
- **Strong** — never GC'd while reachable.
- **Soft** — GC before OOM. Use for caches.
- **Weak** — GC next cycle. `WeakHashMap`, listener registries.
- **Phantom** — enqueued after finalization for cleanup (replaces `finalize()`).

## Java Memory Model (JMM)
Defines visibility & ordering for shared variables. **happens-before** rules:
1. Program order in a thread.
2. Monitor lock unlock → subsequent lock.
3. `volatile` write → subsequent read.
4. Thread `start()` → run; `join()` → completion.
5. Final field init (constructor) → reader.

## volatile vs synchronized vs Atomic
| | Visibility | Atomicity | Mutual exclusion |
|---|---|---|---|
| `volatile` | ✅ | ❌ (not for compound ops) | ❌ |
| `synchronized` | ✅ | ✅ | ✅ (heavier) |
| `AtomicInteger` (CAS) | ✅ | ✅ (single var) | ❌ (lock-free) |

## ClassLoaders
Bootstrap → Platform → Application → Custom.
Spring Boot fat-jar uses `LaunchedURLClassLoader` to load nested JARs.

## Common OOMs
| Error | Cause | Fix |
|---|---|---|
| `Java heap space` | leak / undersized heap | heap dump (`jmap -dump`) → MAT |
| `Metaspace` | class loader leak (hot redeploys, dynamic proxies) | bump `-XX:MaxMetaspaceSize`, fix leak |
| `Direct buffer memory` | NIO leak | `-XX:MaxDirectMemorySize` |
| `unable to create new native thread` | thread leak | `jstack`, bound thread pools |

## Diagnostic toolbox
`jps`, `jstat -gc`, `jmap`, `jstack`, `jfr`, `async-profiler`, GC logs (`-Xlog:gc*`).