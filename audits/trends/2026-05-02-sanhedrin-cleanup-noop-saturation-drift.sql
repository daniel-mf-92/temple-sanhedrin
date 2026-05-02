-- Historical drift audit: Sanhedrin CLEANUP no-op saturation.
-- Read-only verification:
-- sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-02-sanhedrin-cleanup-noop-saturation-drift.sql

.headers on
.mode column

-- 1. Overall CLEANUP volume and structured-evidence gaps.
SELECT
  COUNT(*) AS cleanup_rows,
  MIN(ts) AS first_ts,
  MAX(ts) AS last_ts,
  ROUND((julianday(MAX(ts)) - julianday(MIN(ts))) * 24.0, 2) AS span_hours,
  ROUND(COUNT(*) / ((julianday(MAX(ts)) - julianday(MIN(ts))) * 24.0), 2) AS rows_per_hour,
  SUM(CASE WHEN COALESCE(validation_cmd, '') = '' THEN 1 ELSE 0 END) AS empty_validation_cmd,
  SUM(CASE WHEN COALESCE(validation_result, '') = '' THEN 1 ELSE 0 END) AS empty_validation_result,
  SUM(CASE WHEN duration_sec IS NULL THEN 1 ELSE 0 END) AS null_duration_sec,
  SUM(CASE WHEN COALESCE(error_msg, '') = '' THEN 1 ELSE 0 END) AS empty_error_msg
FROM iterations
WHERE agent = 'sanhedrin'
  AND task_id = 'CLEANUP';

-- 2. Classify cleanup rows by observable deletion outcome.
WITH cleanup AS (
  SELECT
    id,
    ts,
    status,
    notes,
    CASE
      WHEN notes = 'test insert' THEN 'test_insert'
      WHEN notes LIKE '%count=0%'
        OR notes LIKE '%Deleted 0%'
        OR notes LIKE '%deleted=0%'
        OR notes LIKE '%: 0%' THEN 'zero_delete'
      WHEN notes LIKE '%count=%'
        OR notes GLOB '*[0-9]*' THEN 'nonzero_or_unparsed_count'
      ELSE 'unparsed'
    END AS class
  FROM iterations
  WHERE agent = 'sanhedrin'
    AND task_id = 'CLEANUP'
)
SELECT
  class,
  COUNT(*) AS rows,
  MIN(ts) AS first_ts,
  MAX(ts) AS last_ts
FROM cleanup
GROUP BY class
ORDER BY rows DESC;

-- 3. Daily cleanup share of all Sanhedrin rows.
WITH sanhedrin_daily AS (
  SELECT date(ts) AS day, COUNT(*) AS sanhedrin_rows
  FROM iterations
  WHERE agent = 'sanhedrin'
  GROUP BY date(ts)
),
cleanup_daily AS (
  SELECT
    date(ts) AS day,
    COUNT(*) AS cleanup_rows,
    SUM(CASE
      WHEN notes LIKE '%count=0%'
        OR notes LIKE '%Deleted 0%'
        OR notes LIKE '%deleted=0%'
        OR notes LIKE '%: 0%' THEN 1
      ELSE 0
    END) AS zero_delete_rows
  FROM iterations
  WHERE agent = 'sanhedrin'
    AND task_id = 'CLEANUP'
  GROUP BY date(ts)
)
SELECT
  cleanup_daily.day,
  sanhedrin_daily.sanhedrin_rows,
  cleanup_daily.cleanup_rows,
  cleanup_daily.zero_delete_rows,
  ROUND(100.0 * cleanup_daily.cleanup_rows / sanhedrin_daily.sanhedrin_rows, 1) AS cleanup_pct
FROM cleanup_daily
JOIN sanhedrin_daily USING (day)
ORDER BY cleanup_daily.day;

-- 4. Longest consecutive zero-delete CLEANUP streaks.
WITH cleanup AS (
  SELECT
    id,
    ts,
    CASE
      WHEN notes LIKE '%count=0%'
        OR notes LIKE '%Deleted 0%'
        OR notes LIKE '%deleted=0%'
        OR notes LIKE '%: 0%' THEN 1
      ELSE 0
    END AS is_zero_delete
  FROM iterations
  WHERE agent = 'sanhedrin'
    AND task_id = 'CLEANUP'
),
runs AS (
  SELECT
    id,
    ts,
    is_zero_delete,
    SUM(CASE WHEN is_zero_delete = 0 THEN 1 ELSE 0 END)
      OVER (ORDER BY id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS run_group
  FROM cleanup
),
zero_runs AS (
  SELECT
    run_group,
    COUNT(*) AS streak_len,
    MIN(ts) AS first_ts,
    MAX(ts) AS last_ts
  FROM runs
  WHERE is_zero_delete = 1
  GROUP BY run_group
)
SELECT
  streak_len,
  first_ts,
  last_ts
FROM zero_runs
ORDER BY streak_len DESC
LIMIT 10;

-- 5. Distinct CLEANUP note taxonomy, showing normalization drift.
SELECT
  notes,
  COUNT(*) AS rows,
  MIN(ts) AS first_ts,
  MAX(ts) AS last_ts
FROM iterations
WHERE agent = 'sanhedrin'
  AND task_id = 'CLEANUP'
GROUP BY notes
ORDER BY rows DESC, notes
LIMIT 25;
