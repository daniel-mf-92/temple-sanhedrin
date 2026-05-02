-- Historical Law 7 structured-error drift audit.
-- Read-only verification against:
-- /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
--
-- Usage:
-- sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-02-law7-error-msg-structuring-drift.sql

.headers on
.mode column

SELECT
  agent,
  COUNT(*) AS all_rows,
  SUM(status IN ('fail','blocked')) AS nonpass_rows
FROM iterations
GROUP BY agent;

SELECT
  agent,
  COUNT(*) AS nonpass_rows,
  SUM(error_msg IS NULL OR TRIM(error_msg) = '') AS missing_error_msg,
  ROUND(
    100.0 * SUM(error_msg IS NULL OR TRIM(error_msg) = '') / COUNT(*),
    2
  ) AS missing_pct,
  SUM(validation_result IS NULL OR TRIM(validation_result) = '') AS missing_validation_result,
  SUM(notes IS NULL OR TRIM(notes) = '') AS missing_notes
FROM iterations
WHERE status IN ('fail','blocked')
GROUP BY agent
ORDER BY nonpass_rows DESC;

SELECT
  status,
  COUNT(*) AS rows,
  SUM(error_msg IS NULL OR TRIM(error_msg) = '') AS missing_error_msg,
  ROUND(
    100.0 * SUM(error_msg IS NULL OR TRIM(error_msg) = '') / COUNT(*),
    2
  ) AS missing_pct
FROM iterations
WHERE status IN ('fail','blocked')
GROUP BY status;

SELECT
  agent,
  status,
  task_id,
  COUNT(*) AS rows,
  SUM(error_msg IS NULL OR TRIM(error_msg) = '') AS missing_error_msg,
  COUNT(DISTINCT COALESCE(error_msg,'')) AS distinct_error_msg,
  COUNT(DISTINCT COALESCE(notes,'')) AS distinct_notes,
  MIN(ts) AS first_ts,
  MAX(ts) AS last_ts
FROM iterations
WHERE status IN ('fail','blocked')
GROUP BY agent, status, task_id
ORDER BY rows DESC
LIMIT 25;

WITH nonpass AS (
  SELECT
    agent,
    task_id,
    status,
    validation_result,
    error_msg,
    notes
  FROM iterations
  WHERE status IN ('fail','blocked')
),
classified AS (
  SELECT
    agent,
    task_id,
    status,
    CASE
      WHEN LOWER(COALESCE(error_msg,'') || ' ' || COALESCE(validation_result,'') || ' ' || COALESCE(notes,'')) LIKE '%readonly%' THEN 'readonly'
      WHEN LOWER(COALESCE(error_msg,'') || ' ' || COALESCE(validation_result,'') || ' ' || COALESCE(notes,'')) LIKE '%command not found%' THEN 'command not found'
      WHEN LOWER(COALESCE(error_msg,'') || ' ' || COALESCE(validation_result,'') || ' ' || COALESCE(notes,'')) LIKE '%operation not permitted%' THEN 'operation not permitted'
      WHEN LOWER(COALESCE(error_msg,'') || ' ' || COALESCE(validation_result,'') || ' ' || COALESCE(notes,'')) LIKE '%no such file%' THEN 'no such file'
      WHEN LOWER(COALESCE(error_msg,'') || ' ' || COALESCE(validation_result,'') || ' ' || COALESCE(notes,'')) LIKE '%timeout%' THEN 'timeout'
      WHEN LOWER(COALESCE(error_msg,'') || ' ' || COALESCE(validation_result,'') || ' ' || COALESCE(notes,'')) LIKE '%blocked%' THEN 'blocked literal'
      ELSE 'unclassified'
    END AS blocker_family,
    CASE WHEN error_msg IS NULL OR TRIM(error_msg) = '' THEN 1 ELSE 0 END AS error_missing
  FROM nonpass
)
SELECT
  blocker_family,
  COUNT(*) AS rows,
  SUM(error_missing) AS rows_missing_error_msg,
  COUNT(DISTINCT agent || ':' || task_id || ':' || status) AS task_status_buckets
FROM classified
GROUP BY blocker_family
ORDER BY rows DESC;

WITH ordered AS (
  SELECT
    id,
    agent,
    LOWER(COALESCE(error_msg,'')) AS err,
    LAG(LOWER(COALESCE(error_msg,''))) OVER (PARTITION BY agent ORDER BY id) AS prev_err_1,
    LAG(LOWER(COALESCE(error_msg,'')), 2) OVER (PARTITION BY agent ORDER BY id) AS prev_err_2
  FROM iterations
  WHERE status IN ('fail','blocked')
)
SELECT
  agent,
  COUNT(*) AS consecutive_3_same_structured_error_windows
FROM ordered
WHERE err <> ''
  AND err = prev_err_1
  AND err = prev_err_2
GROUP BY agent;

WITH ordered AS (
  SELECT
    id,
    agent,
    CASE
      WHEN LOWER(COALESCE(error_msg,'') || ' ' || COALESCE(validation_result,'') || ' ' || COALESCE(notes,'')) LIKE '%readonly%' THEN 'readonly'
      WHEN LOWER(COALESCE(error_msg,'') || ' ' || COALESCE(validation_result,'') || ' ' || COALESCE(notes,'')) LIKE '%command not found%' THEN 'command not found'
      WHEN LOWER(COALESCE(error_msg,'') || ' ' || COALESCE(validation_result,'') || ' ' || COALESCE(notes,'')) LIKE '%operation not permitted%' THEN 'operation not permitted'
      WHEN LOWER(COALESCE(error_msg,'') || ' ' || COALESCE(validation_result,'') || ' ' || COALESCE(notes,'')) LIKE '%no such file%' THEN 'no such file'
      WHEN LOWER(COALESCE(error_msg,'') || ' ' || COALESCE(validation_result,'') || ' ' || COALESCE(notes,'')) LIKE '%timeout%' THEN 'timeout'
      WHEN LOWER(COALESCE(error_msg,'') || ' ' || COALESCE(validation_result,'') || ' ' || COALESCE(notes,'')) LIKE '%blocked%' THEN 'blocked literal'
      ELSE 'unclassified'
    END AS family
  FROM iterations
  WHERE status IN ('fail','blocked')
),
lagged AS (
  SELECT
    agent,
    family,
    LAG(family) OVER (PARTITION BY agent ORDER BY id) AS prev_family_1,
    LAG(family, 2) OVER (PARTITION BY agent ORDER BY id) AS prev_family_2
  FROM ordered
)
SELECT
  agent,
  family,
  COUNT(*) AS consecutive_3_same_family_windows
FROM lagged
WHERE family <> 'unclassified'
  AND family = prev_family_1
  AND family = prev_family_2
GROUP BY agent, family
ORDER BY consecutive_3_same_family_windows DESC;

SELECT
  task_id,
  ts,
  status,
  SUBSTR(notes, 1, 120) AS note_excerpt
FROM iterations
WHERE status IN ('fail','blocked')
ORDER BY id
LIMIT 15;
