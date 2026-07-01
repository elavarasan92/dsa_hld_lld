-- =============================================================
-- 20 PostgreSQL Interview Queries — Principal Level
-- =============================================================

-- 1. Nth highest salary per dept (handles ties)
SELECT * FROM (
  SELECT e.*, DENSE_RANK() OVER (PARTITION BY dept_id ORDER BY salary DESC) r
  FROM employee e
) x WHERE r = :n;

-- 2. Employees earning more than dept average
SELECT e.* FROM employee e
JOIN (SELECT dept_id, AVG(salary) a FROM employee GROUP BY dept_id) d
  ON d.dept_id = e.dept_id
WHERE e.salary > d.a;

-- 3. Running total of bookings per day
SELECT booking_date,
       SUM(amount) OVER (ORDER BY booking_date
                         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running
FROM booking;

-- 4. Find duplicate emails
SELECT email, COUNT(*)
FROM users GROUP BY email HAVING COUNT(*) > 1;

-- 5. Delete duplicates keeping lowest id
DELETE FROM users a USING users b
WHERE a.email = b.email AND a.id > b.id;

-- 6. Gaps in sequential ids
SELECT id + 1 AS gap_start FROM t t1
WHERE NOT EXISTS (SELECT 1 FROM t t2 WHERE t2.id = t1.id + 1);

-- 7. Pivot: monthly revenue per region (FILTER)
SELECT region,
  SUM(amount) FILTER (WHERE month = 1) AS jan,
  SUM(amount) FILTER (WHERE month = 2) AS feb,
  SUM(amount) FILTER (WHERE month = 3) AS mar
FROM sales GROUP BY region;

-- 8. Top 3 products per category
SELECT * FROM (
  SELECT p.*, ROW_NUMBER() OVER (PARTITION BY category ORDER BY sales DESC) r
  FROM products p
) x WHERE r <= 3;

-- 9. Containers idle > 7 days (demurrage candidates)
SELECT container_id
FROM container_history
GROUP BY container_id
HAVING MAX(ts) < now() - INTERVAL '7 days';

-- 10. Booking status changes (gaps & islands)
SELECT booking_id, status, MIN(ts) AS start_ts, MAX(ts) AS end_ts
FROM (
  SELECT booking_id, status, ts,
    ROW_NUMBER() OVER (PARTITION BY booking_id ORDER BY ts)
  - ROW_NUMBER() OVER (PARTITION BY booking_id, status ORDER BY ts) AS grp
  FROM booking_audit
) t
GROUP BY booking_id, status, grp
ORDER BY booking_id, start_ts;

-- 11. Recursive CTE: org hierarchy
WITH RECURSIVE tree AS (
  SELECT id, manager_id, name, 1 AS lvl FROM emp WHERE manager_id IS NULL
  UNION ALL
  SELECT e.id, e.manager_id, e.name, t.lvl + 1
  FROM emp e JOIN tree t ON e.manager_id = t.id
)
SELECT * FROM tree ORDER BY lvl;

-- 12. JSONB query: containers carrying hazmat
CREATE INDEX IF NOT EXISTS idx_container_attrs ON container USING GIN (attrs);
SELECT * FROM container WHERE attrs @> '{"hazmat":true}';

-- 13. UPSERT (idempotent insert) — ignore late events
INSERT INTO snapshot(container_id, lat, lon, ts)
VALUES (:id, :lat, :lon, :ts)
ON CONFLICT (container_id) DO UPDATE
  SET lat = EXCLUDED.lat, lon = EXCLUDED.lon, ts = EXCLUDED.ts
  WHERE snapshot.ts < EXCLUDED.ts;

-- 14. Slow queries (requires pg_stat_statements)
SELECT query, calls, mean_exec_time, total_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC LIMIT 20;

-- 15. Lock wait diagnosis
SELECT blocked.pid    AS blocked_pid,
       blocking.pid   AS blocking_pid,
       blocked.query  AS blocked_query,
       blocking.query AS blocking_query
FROM pg_stat_activity blocked
JOIN pg_stat_activity blocking
  ON blocking.pid = ANY(pg_blocking_pids(blocked.pid));

-- 16. Partial index for active rows only
CREATE INDEX IF NOT EXISTS idx_active_orders
  ON orders(customer_id) WHERE status = 'ACTIVE';

-- 17. Covering index (avoid heap lookup)
CREATE INDEX IF NOT EXISTS idx_booking_customer_inc
  ON booking(customer_id) INCLUDE (status, total);

-- 18. Median salary
SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY salary) FROM emp;

-- 19. Date series fill
SELECT d::date AS day, COALESCE(SUM(amount), 0) AS total
FROM generate_series(:from, :to, '1 day') d
LEFT JOIN sales s ON s.sale_date = d::date
GROUP BY d ORDER BY d;

-- 20. Advisory lock for app-level singleton job
SELECT pg_try_advisory_lock(42);  -- run nightly job only on one node
-- ... do work ...
SELECT pg_advisory_unlock(42);