-- Historical validation result normalization drift audit.
-- Read-only query pack for:
--   /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
--
-- Run with:
--   sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-30-validation-result-normalization-drift.sql

.headers on
.mode column

SELECT
  COUNT(*) AS total_rows,
  MIN(ts) AS first_ts,
  MAX(ts) AS last_ts
FROM iterations;

WITH norm AS (
  SELECT
    id,
    ts,
    agent,
    task_id,
    status,
    COALESCE(TRIM(validation_cmd), '') AS cmd,
    COALESCE(TRIM(validation_result), '') AS result,
    COALESCE(TRIM(error_msg), '') AS err
  FROM iterations
)
SELECT
  agent,
  COUNT(*) AS rows,
  SUM(cmd = '') AS missing_cmd,
  SUM(result = '') AS missing_result,
  SUM(status IN ('fail', 'blocked') AND err = '') AS nonpass_without_error,
  SUM(status = 'pass' AND err <> '') AS pass_with_error,
  SUM(status = 'pass' AND (
    LOWER(result) LIKE '%fail%' OR
    LOWER(result) LIKE '%error%' OR
    LOWER(result) LIKE '%traceback%'
  )) AS pass_result_negative_token,
  SUM(status IN ('fail', 'blocked') AND (
    LOWER(result) LIKE '%ok%' OR
    LOWER(result) LIKE '%passed%' OR
    LOWER(result) LIKE '%exit 0%'
  )) AS nonpass_result_success_token
FROM norm
GROUP BY agent
ORDER BY agent;

WITH norm AS (
  SELECT
    agent,
    status,
    COALESCE(TRIM(validation_result), '') AS result
  FROM iterations
),
classes AS (
  SELECT
    agent,
    status,
    CASE
      WHEN result = '' THEN 'missing'
      WHEN LOWER(result) IN ('ok', 'exit 0') THEN 'coarse_success'
      WHEN LOWER(result) LIKE '%skipped%' OR LOWER(result) LIKE '%unavailable%' THEN 'success_with_skip'
      WHEN LOWER(result) LIKE '%passed%' OR LOWER(result) LIKE '%_checks=ok%' THEN 'specific_success'
      ELSE 'other'
    END AS result_class
  FROM norm
)
SELECT
  agent,
  status,
  result_class,
  COUNT(*) AS rows
FROM classes
GROUP BY agent, status, result_class
ORDER BY agent, status, rows DESC;

SELECT
  COUNT(*) AS non_iso_timestamp_rows
FROM iterations
WHERE ts NOT GLOB '????-??-??T??:??:??*';

SELECT
  id,
  ts,
  agent,
  task_id,
  status
FROM iterations
WHERE ts NOT GLOB '????-??-??T??:??:??*'
ORDER BY id;

SELECT
  id,
  ts,
  agent,
  task_id,
  status,
  validation_cmd,
  validation_result
FROM iterations
WHERE agent = 'modernization'
  AND status = 'pass'
  AND (
    LOWER(validation_result) LIKE '%fail%' OR
    LOWER(validation_result) LIKE '%error%' OR
    LOWER(validation_result) LIKE '%traceback%'
  )
ORDER BY ts;

WITH norm AS (
  SELECT
    id,
    ts,
    agent,
    task_id,
    status,
    COALESCE(TRIM(validation_cmd), '') AS cmd,
    COALESCE(TRIM(validation_result), '') AS result,
    COALESCE(TRIM(error_msg), '') AS err
  FROM iterations
)
SELECT
  id,
  ts,
  agent,
  task_id,
  status,
  cmd,
  result,
  err
FROM norm
WHERE cmd = ''
   OR result = ''
   OR (status IN ('fail', 'blocked') AND err = '')
   OR (status = 'pass' AND err <> '')
ORDER BY ts, id
LIMIT 40;
