-- Historical duration nullability drift for Law 7 liveness backtesting.
-- Read with:
-- sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-02-duration-null-liveness-blindspot.sql

.headers on
.mode column

SELECT
  agent,
  COUNT(*) AS rows,
  SUM(duration_sec IS NULL) AS null_duration_rows,
  SUM(duration_sec = 0) AS literal_zero_duration_rows,
  MIN(duration_sec) AS min_duration_sec,
  MAX(duration_sec) AS max_duration_sec,
  SUM(COALESCE(validation_cmd, '') <> '') AS rows_with_validation_cmd,
  SUM((COALESCE(validation_cmd, '') <> '') AND duration_sec IS NULL) AS command_rows_with_null_duration
FROM iterations
GROUP BY agent
ORDER BY agent;

WITH classified AS (
  SELECT
    *,
    CASE WHEN ts GLOB '[0-9][0-9][0-9][0-9]-*' THEN substr(ts, 1, 10) ELSE 'non-iso' END AS day,
    (
      COALESCE(validation_cmd, '') LIKE '%qemu%'
      OR COALESCE(validation_cmd, '') LIKE '%QEMU%'
      OR COALESCE(validation_result, '') LIKE '%qemu%'
      OR COALESCE(validation_result, '') LIKE '%QEMU%'
      OR COALESCE(notes, '') LIKE '%qemu%'
      OR COALESCE(notes, '') LIKE '%QEMU%'
    ) AS qemu_row,
    (
      COALESCE(validation_cmd, '') LIKE '%timeout%'
      OR COALESCE(validation_result, '') LIKE '%timeout%'
      OR COALESCE(error_msg, '') LIKE '%timeout%'
      OR COALESCE(notes, '') LIKE '%timeout%'
    ) AS timeout_row,
    (
      COALESCE(validation_cmd, '') LIKE '%python%'
      OR COALESCE(validation_cmd, '') LIKE '%pytest%'
    ) AS python_row
  FROM iterations
)
SELECT
  agent,
  SUM(qemu_row) AS qemu_rows,
  SUM(qemu_row AND duration_sec IS NULL) AS qemu_null_duration_rows,
  SUM(timeout_row) AS timeout_rows,
  SUM(timeout_row AND duration_sec IS NULL) AS timeout_null_duration_rows,
  SUM(python_row) AS python_rows,
  SUM(python_row AND duration_sec IS NULL) AS python_null_duration_rows
FROM classified
WHERE agent IN ('modernization', 'inference')
GROUP BY agent
ORDER BY agent;

WITH classified AS (
  SELECT
    *,
    CASE WHEN ts GLOB '[0-9][0-9][0-9][0-9]-*' THEN substr(ts, 1, 10) ELSE 'non-iso' END AS day,
    COALESCE(validation_cmd, '') <> '' AS has_validation_cmd,
    (
      COALESCE(error_msg, '') <> ''
      OR lower(COALESCE(validation_result, '')) LIKE '%fail%'
      OR lower(COALESCE(validation_result, '')) LIKE '%error%'
      OR lower(COALESCE(validation_result, '')) LIKE '%timeout%'
    ) AS error_signal
  FROM iterations
)
SELECT
  day,
  agent,
  COUNT(*) AS rows,
  SUM(duration_sec IS NULL) AS null_duration_rows,
  SUM(has_validation_cmd) AS rows_with_validation_cmd,
  SUM(has_validation_cmd AND duration_sec IS NULL) AS command_rows_with_null_duration,
  SUM(error_signal) AS error_signal_rows,
  SUM(error_signal AND duration_sec IS NULL) AS error_signal_null_duration_rows
FROM classified
WHERE agent IN ('modernization', 'inference')
GROUP BY day, agent
ORDER BY day, agent;

SELECT
  agent,
  status,
  COUNT(*) AS rows,
  SUM(duration_sec IS NULL) AS null_duration_rows
FROM iterations
GROUP BY agent, status
ORDER BY agent, rows DESC;

WITH classified AS (
  SELECT
    *,
    (
      COALESCE(error_msg, '') <> ''
      OR lower(COALESCE(validation_result, '')) LIKE '%fail%'
      OR lower(COALESCE(validation_result, '')) LIKE '%error%'
      OR lower(COALESCE(validation_result, '')) LIKE '%timeout%'
    ) AS error_signal
  FROM iterations
)
SELECT
  id,
  ts,
  agent,
  task_id,
  status,
  duration_sec,
  substr(validation_cmd, 1, 90) AS validation_cmd,
  substr(validation_result, 1, 90) AS validation_result,
  substr(error_msg, 1, 90) AS error_msg
FROM classified
WHERE agent IN ('modernization', 'inference')
  AND duration_sec IS NULL
  AND (COALESCE(validation_cmd, '') <> '' OR COALESCE(validation_result, '') <> '' OR error_signal)
ORDER BY id
LIMIT 20;

