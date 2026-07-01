-- 1. Nth highest salary per dept (gaps & ties)
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
                         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) running
FROM booking;

-- 4. Find duplicate emails
SELECT email, COUNT(*) FROM users GROUP BY email HAVING COUNT(*) > 1;

-- 5. Delete duplicates keeping lowest id
DELETE FROM users a USING users b
WHERE a.email = b.email AND a.id > b.id;

-- 6. Gaps in sequential ids
SELECT id+1 AS gap_start FROM t t1
WHERE NOT EXISTS (SELECT 1 FROM t t2 WHERE t2.id = t1.id+1);

-- 7. Pivot: monthly revenue per region (FILTER)
SELECT region,
  SUM(amount) FILTER (WHERE month=1) jan,
  SUM(amount) FILTER (WHERE month=2) feb
FROM sales GROUP BY region;

-- 8. Top 3 products per category
SELECT * FROM (
  SELECT p.*, ROW_NUMBER() OVER (PARTITION BY category ORDER BY sales DESC) r
  FROM products p) x WHERE r <= 3;

-- 9. Containers idle > 7 days (demurrage candidates)
SELECT container_id FROM container_history
GROUP BY container_id
HAVING MAX(ts) < now() - INTERVAL '7 days';

-- 10. Booking status changes (gaps & islands)
SELECT booking_id, status, MIN(ts) start_ts, MAX(ts) end_ts
FROM (
  SELECT booking_id, status, ts,
    ROW_NUMBER() OVER (PARTITION BY booking_id ORDER BY ts)
  - ROW_NUMBER() OVER (PARTITION BY booking_id, status ORDER BY ts) grp
  FROM booking_audit
) t GROUP BY booking_id, status, grp ORDER BY booking_id, start_ts;

-- 11. Recursive CTE: org hierarchy
WITH RECURSIVE tree AS (
  SELECT id, manager_id, name, 1 lvl FROM emp WHERE manager_id IS NULL
  UNION ALL
  SELECT e.id, e.manager_id, e.name, t.lvl+1
  FROM emp e JOIN tree t ON e.manager_id = t.id
) SELECT * FROM tree;

-- 12. JSONB query: containers carrying hazmat
SELECT * FROM container WHERE attrs @> '{"hazmat":true}';
CREATE INDEX ON container USING GIN (attrs);

-- 13. UPSERT (idempotent insert)
INSERT INTO snapshot(container_id, lat, lon, ts)
VALUES (:id,:lat,:lon,:ts)
ON CONFLICT (container_id) DO UPDATE
  SET lat=EXCLUDED.lat, lon=EXCLUDED.lon, ts=EXCLUDED.ts
  WHERE snapshot.ts < EXCLUDED.ts;   -- ignore late events

-- 14. Find slow queries from pg_stat_statements
SELECT query, calls, mean_exec_time, total_exec_time
FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 20;

-- 15. Lock wait diagnosis
SELECT blocked.pid blocked_pid, blocking.pid blocking_pid,
       blocked.query blocked_query, blocking.query blocking_query
FROM pg_stat_activity blocked
JOIN pg_stat_activity blocking ON blocking.pid = ANY(pg_blocking_pids(blocked.pid));

-- 16. Partial index for active rows only
CREATE INDEX idx_active_orders ON orders(customer_id) WHERE status='ACTIVE';

-- 17. Covering index (avoid table lookup)
CREATE INDEX ON booking(customer_id) INCLUDE (status, total);

-- 18. Median salary (percentile_cont)
SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY salary) FROM emp;

-- 19. Date series fill (LEFT JOIN generate_series)
SELECT d::date, COALESCE(SUM(amount),0)
FROM generate_series(:from,:to,'1 day') d
LEFT JOIN sales s ON s.sale_date = d::date
GROUP BY d ORDER BY d;

-- 20. Advisory lock for app-level singleton job
SELECT pg_try_advisory_lock(42); -- run nightly job only on one node