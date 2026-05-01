-- Historical validation timeout-containment drift audit.
-- Source DB: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Run with:
--   sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-01-validation-timeout-containment-drift.sql

.headers on
.mode column

WITH builder_rows AS (
  SELECT
    id,
    ts,
    agent,
    task_id,
    status,
    validation_cmd,
    validation_result,
    error_msg,
    duration_sec,
    CASE
      WHEN lower(coalesce(validation_cmd, '')) LIKE '%timeout%'
        OR lower(coalesce(validation_cmd, '')) LIKE '%timeout_sec%'
        OR lower(coalesce(validation_cmd, '')) LIKE '%gtimeout%'
      THEN 1 ELSE 0
    END AS has_timeout,
    CASE WHEN lower(coalesce(validation_cmd, '')) LIKE '%qemu%' THEN 1 ELSE 0 END AS mentions_qemu,
    CASE WHEN lower(coalesce(validation_cmd, '')) LIKE '%pytest%' THEN 1 ELSE 0 END AS mentions_pytest,
    CASE
      WHEN lower(coalesce(validation_result, '')) LIKE '%timeout%'
        OR lower(coalesce(error_msg, '')) LIKE '%timeout%'
      THEN 1 ELSE 0
    END AS result_mentions_timeout
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
)
SELECT
  'overall_timeout_coverage' AS section,
  agent,
  count(*) AS rows,
  sum(has_timeout) AS timeout_rows,
  count(*) - sum(has_timeout) AS no_timeout_rows,
  printf('%.1f%%', 100.0 * sum(has_timeout) / count(*)) AS timeout_pct,
  sum(CASE WHEN duration_sec IS NULL THEN 1 ELSE 0 END) AS null_duration_rows
FROM builder_rows
GROUP BY agent
ORDER BY agent;

WITH builder_rows AS (
  SELECT
    ts,
    agent,
    CASE
      WHEN lower(coalesce(validation_cmd, '')) LIKE '%timeout%'
        OR lower(coalesce(validation_cmd, '')) LIKE '%timeout_sec%'
        OR lower(coalesce(validation_cmd, '')) LIKE '%gtimeout%'
      THEN 1 ELSE 0
    END AS has_timeout
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
)
SELECT
  'daily_timeout_coverage' AS section,
  agent,
  substr(ts, 1, 10) AS day,
  count(*) AS rows,
  sum(has_timeout) AS timeout_rows,
  count(*) - sum(has_timeout) AS no_timeout_rows
FROM builder_rows
GROUP BY agent, day
ORDER BY day DESC, agent;

WITH builder_rows AS (
  SELECT
    id,
    ts,
    agent,
    task_id,
    lower(coalesce(validation_cmd, '')) AS cmd,
    CASE
      WHEN lower(coalesce(validation_cmd, '')) LIKE '%timeout%'
        OR lower(coalesce(validation_cmd, '')) LIKE '%timeout_sec%'
        OR lower(coalesce(validation_cmd, '')) LIKE '%gtimeout%'
      THEN 1 ELSE 0
    END AS has_timeout
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
)
SELECT
  'high_risk_command_families' AS section,
  agent,
  count(*) AS rows,
  sum(CASE WHEN cmd LIKE '%qemu%' THEN 1 ELSE 0 END) AS qemu_rows,
  sum(CASE WHEN cmd LIKE '%qemu%' AND has_timeout = 0 THEN 1 ELSE 0 END) AS qemu_no_timeout_rows,
  sum(CASE WHEN cmd LIKE '%pytest%' THEN 1 ELSE 0 END) AS pytest_rows,
  sum(CASE WHEN cmd LIKE '%pytest%' AND has_timeout = 0 THEN 1 ELSE 0 END) AS pytest_no_timeout_rows
FROM builder_rows
GROUP BY agent
ORDER BY agent;

WITH builder_rows AS (
  SELECT
    id,
    ts,
    agent,
    task_id,
    status,
    lower(coalesce(validation_cmd, '')) AS cmd,
    CASE
      WHEN lower(coalesce(validation_cmd, '')) LIKE '%timeout%'
        OR lower(coalesce(validation_cmd, '')) LIKE '%timeout_sec%'
        OR lower(coalesce(validation_cmd, '')) LIKE '%gtimeout%'
      THEN 1 ELSE 0
    END AS has_timeout,
    CASE
      WHEN lower(coalesce(validation_result, '')) LIKE '%timeout%'
        OR lower(coalesce(error_msg, '')) LIKE '%timeout%'
      THEN 1 ELSE 0
    END AS result_mentions_timeout
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
)
SELECT
  'status_timeout_mentions' AS section,
  agent,
  status,
  count(*) AS rows,
  sum(has_timeout) AS cmd_timeout_rows,
  sum(result_mentions_timeout) AS result_timeout_mentions
FROM builder_rows
GROUP BY agent, status
ORDER BY agent, status;

SELECT
  'latest_inference_no_timeout' AS section,
  agent,
  task_id,
  ts,
  substr(validation_cmd, 1, 180) AS validation_cmd
FROM iterations
WHERE agent = 'inference'
  AND validation_cmd IS NOT NULL
  AND trim(validation_cmd) <> ''
ORDER BY id DESC
LIMIT 12;

SELECT
  'latest_modernization_qemu_no_timeout' AS section,
  agent,
  task_id,
  ts,
  substr(validation_cmd, 1, 180) AS validation_cmd
FROM iterations
WHERE agent = 'modernization'
  AND lower(coalesce(validation_cmd, '')) LIKE '%qemu%'
  AND lower(coalesce(validation_cmd, '')) NOT LIKE '%timeout%'
  AND lower(coalesce(validation_cmd, '')) NOT LIKE '%timeout_sec%'
  AND lower(coalesce(validation_cmd, '')) NOT LIKE '%gtimeout%'
ORDER BY id DESC
LIMIT 12;
