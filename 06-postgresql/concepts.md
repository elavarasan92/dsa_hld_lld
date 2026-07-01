# 🗄️ PostgreSQL — Principal-Level

## Indexes
| Type | Best for |
|---|---|
| **B-tree** (default) | equality + range |
| **Hash** | equality only |
| **GIN** | full-text, JSONB, arrays |
| **GiST** | geometry, ranges |
| **BRIN** | huge ordered tables (time-series), tiny index size |

- **Partial index**: `WHERE status='ACTIVE'` — smaller, faster.
- **Covering index**: `INCLUDE (col)` — avoids heap visit (index-only scan).
- **Expression index**: `ON t (lower(email))`.

## EXPLAIN / EXPLAIN ANALYZE
- Look for: **Seq Scan** on big tables, high "rows removed by filter", nested loops with high outer rows.
- Use `BUFFERS` to see cache hits.

## Optimization Techniques
- Avoid `SELECT *`.
- Replace `OR` with `UNION` when planner picks Seq Scan.
- Run `ANALYZE` after bulk loads to refresh stats.
- Tune `work_mem` for sorts/hashes.
- Use `LATERAL` joins for top-N per group.

## Isolation Levels
| Level | Notes |
|---|---|
| Read Uncommitted | PG treats as Read Committed |
| **Read Committed** (default) | sees committed data; non-repeatable reads possible |
| **Repeatable Read** | snapshot isolation; no phantom reads |
| **Serializable** | true serializable via SSI; may abort with `40001` |

## MVCC
- Each tx sees a snapshot.
- Updates create new tuple versions; old ones cleaned by **VACUUM**.
- **Autovacuum** runs automatically; tune for write-heavy tables.
- Bloat = dead tuples not yet reclaimed → `pg_stat_user_tables.n_dead_tup`.

## Window Functions
```sql
ROW_NUMBER() OVER (PARTITION BY dept ORDER BY salary DESC)
RANK / DENSE_RANK / LAG / LEAD / NTILE / SUM ... OVER (...)
```

## CTE
- PG ≤11: optimization fence (always materialized).
- PG 12+: inlined unless `MATERIALIZED` keyword.
- **Recursive** for hierarchies.

## Partitioning
- **Range** (date), **List** (region), **Hash** (even).
- Planner prunes partitions using constraint exclusion / partition pruning.
- Use for tables > 50–100 GB.

## Connection Pooling
- **HikariCP** (app side, fast).
- **PgBouncer** (proxy, transaction-mode pooling) when many app instances → otherwise PG runs out of connections.

## JSONB
- Binary, indexable with GIN.
- `data @> '{"hazmat":true}'` containment.
- Don't use as substitute for proper schema for queryable fields.

## Locking & Deadlocks
- PG auto-detects, kills one tx with `40P01`.
- Diagnose with `pg_stat_activity` + `pg_blocking_pids`.
- Mitigate: consistent lock order, shorter transactions.

## Replication
- **Streaming** (binary WAL) — full cluster, used for HA / read replicas.
- **Logical** (per-table) — cross-version, selective, used for migrations / CDC.

## Useful System Views
| View | Purpose |
|---|---|
| `pg_stat_activity` | running queries, locks |
| `pg_stat_statements` | top queries by total/avg time |
| `pg_stat_user_tables` | seq vs index scans, dead tuples |
| `pg_locks` | current locks |
| `pg_indexes` / `pg_index` | index metadata |