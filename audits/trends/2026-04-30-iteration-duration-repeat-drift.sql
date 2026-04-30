-- Historical iteration duration and repeat-accounting drift audit.
-- Read-only query pack for:
--   /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
--
-- Run with:
--   sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-30-iteration-duration-repeat-drift.sql

.headers on
.mode column

SELECT
  COUNT(*) AS total_rows,
  MIN(ts) AS raw_first_ts,
  MAX(ts) AS raw_last_ts,
  MIN(CASE WHEN ts GLOB '????-??-??T??:??:??*' THEN ts END) AS first_iso_ts,
  MAX(CASE WHEN ts GLOB '????-??-??T??:??:??*' THEN ts END) AS last_iso_ts
FROM iterations;

SELECT
  agent,
  COUNT(*) AS rows,
  SUM(duration_sec IS NULL) AS duration_null,
  SUM(duration_sec = 0) AS duration_zero,
  SUM(duration_sec > 0) AS duration_positive
FROM iterations
GROUP BY agent
ORDER BY agent;

SELECT
  agent,
  status,
  COUNT(*) AS rows,
  SUM(duration_sec IS NULL) AS duration_null
FROM iterations
GROUP BY agent, status
ORDER BY agent, status;

WITH duplicate_tasks AS (
  SELECT
    agent,
    task_id,
    COUNT(*) AS rows,
    MIN(ts) AS first_ts,
    MAX(ts) AS last_ts,
    SUM(lines_added) AS lines_added,
    SUM(lines_removed) AS lines_removed
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
  GROUP BY agent, task_id
  HAVING COUNT(*) > 1
)
SELECT
  agent,
  COUNT(*) AS duplicated_task_ids,
  SUM(rows) AS rows_in_duplicated_tasks,
  MAX(rows) AS max_rows_same_task
FROM duplicate_tasks
GROUP BY agent
ORDER BY agent;

WITH duplicate_tasks AS (
  SELECT
    agent,
    task_id,
    COUNT(*) AS rows,
    MIN(ts) AS first_ts,
    MAX(ts) AS last_ts,
    SUM(lines_added) AS lines_added,
    SUM(lines_removed) AS lines_removed
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
  GROUP BY agent, task_id
  HAVING COUNT(*) > 1
),
duplicate_spans AS (
  SELECT
    agent,
    task_id,
    rows,
    first_ts,
    last_ts,
    lines_added,
    lines_removed,
    CAST((julianday(last_ts) - julianday(first_ts)) * 24 * 60 AS INTEGER) AS span_minutes
  FROM duplicate_tasks
  WHERE first_ts GLOB '????-??-??T??:??:??*'
    AND last_ts GLOB '????-??-??T??:??:??*'
)
SELECT
  agent,
  task_id,
  rows,
  first_ts,
  last_ts,
  span_minutes,
  lines_added,
  lines_removed
FROM duplicate_spans
WHERE span_minutes >= 30
ORDER BY span_minutes DESC, agent, task_id
LIMIT 40;

SELECT
  agent,
  COUNT(*) AS zero_churn_rows,
  SUM(files_changed LIKE '%MASTER_TASKS.md%') AS zero_churn_with_taskfile,
  SUM(
    LOWER(notes) LIKE '%stale%' OR
    LOWER(notes) LIKE '%superseded%' OR
    LOWER(notes) LIKE '%deduplicated%' OR
    LOWER(notes) LIKE '%duplicate%'
  ) AS zero_churn_stale_or_dedupe
FROM iterations
WHERE agent IN ('modernization', 'inference')
  AND COALESCE(lines_added, 0) = 0
  AND COALESCE(lines_removed, 0) = 0
GROUP BY agent
ORDER BY agent;

SELECT
  id,
  ts,
  agent,
  task_id,
  status,
  files_changed,
  lines_added,
  lines_removed,
  validation_result,
  notes
FROM iterations
WHERE agent IN ('modernization', 'inference')
  AND COALESCE(lines_added, 0) = 0
  AND COALESCE(lines_removed, 0) = 0
ORDER BY ts, id;
