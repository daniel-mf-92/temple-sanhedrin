-- Historical/read-only trend audit for status/payload semantic overload.
-- Database: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Reproduce with:
--   sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-01-status-payload-semantic-overload-drift.sql

WITH base AS (
  SELECT
    id,
    ts,
    agent,
    task_id,
    status,
    coalesce(validation_result, '') AS validation_result,
    coalesce(error_msg, '') AS error_msg,
    coalesce(notes, '') AS notes,
    lower(coalesce(validation_result, '') || ' ' || coalesce(notes, '') || ' ' || coalesce(error_msg, '')) AS payload
  FROM iterations
),
flagged AS (
  SELECT
    *,
    payload GLOB '*fail*' AS has_fail_token,
    payload GLOB '*blocked*' AS has_blocked_token,
    payload LIKE '%readonly database%' AS has_readonly_database,
    payload LIKE '%fail_count=0%' AS has_fail_count_zero,
    payload LIKE '%no_critical_violations%' AS has_no_critical_violations,
    payload LIKE '%fail-stop%' AS has_fail_stop_feature,
    payload LIKE '%verify-fail%' AS has_verify_fail_feature,
    payload LIKE '%failure%' AS has_failure_token
  FROM base
)
SELECT
  'status_totals' AS section,
  agent,
  status,
  COUNT(*) AS rows,
  NULL AS extra
FROM flagged
GROUP BY agent, status

UNION ALL

SELECT
  'pass_payload_has_fail_token' AS section,
  agent,
  status,
  COUNT(*) AS rows,
  NULL AS extra
FROM flagged
WHERE status = 'pass' AND has_fail_token
GROUP BY agent, status

UNION ALL

SELECT
  'pass_payload_has_blocked_token' AS section,
  agent,
  status,
  COUNT(*) AS rows,
  NULL AS extra
FROM flagged
WHERE status = 'pass' AND has_blocked_token
GROUP BY agent, status

UNION ALL

SELECT
  'nonpass_missing_structured_cause' AS section,
  agent,
  status,
  COUNT(*) AS rows,
  NULL AS extra
FROM flagged
WHERE status <> 'pass'
  AND trim(error_msg) = ''
  AND trim(validation_result) = ''
GROUP BY agent, status

UNION ALL

SELECT
  'pass_fail_token_bucket' AS section,
  agent,
  status,
  COUNT(*) AS rows,
  CASE
    WHEN has_readonly_database THEN 'readonly_database'
    WHEN has_fail_count_zero THEN 'fail_count_zero'
    WHEN has_no_critical_violations THEN 'no_critical_violations'
    WHEN has_fail_stop_feature THEN 'fail_stop_feature'
    WHEN has_verify_fail_feature THEN 'verify_fail_feature'
    WHEN has_failure_token THEN 'failure_feature_or_evidence'
    WHEN has_blocked_token THEN 'blocked_token'
    ELSE 'other_fail_token'
  END AS extra
FROM flagged
WHERE status = 'pass' AND has_fail_token
GROUP BY agent, status, extra

ORDER BY section, agent, status, extra;

SELECT
  'nonpass_by_task_id' AS section,
  task_id,
  status,
  COUNT(*) AS rows,
  MIN(ts) AS first_ts,
  MAX(ts) AS last_ts
FROM iterations
WHERE agent = 'sanhedrin'
  AND status <> 'pass'
  AND coalesce(trim(error_msg), '') = ''
  AND coalesce(trim(validation_result), '') = ''
GROUP BY task_id, status
ORDER BY rows DESC
LIMIT 15;

SELECT
  'builder_pass_fail_token_samples' AS section,
  id,
  ts,
  agent,
  task_id,
  status,
  substr(validation_result || ' ' || coalesce(notes, ''), 1, 180) AS sample
FROM iterations
WHERE status = 'pass'
  AND agent IN ('modernization', 'inference')
  AND lower(coalesce(validation_result, '') || ' ' || coalesce(notes, '')) GLOB '*fail*'
ORDER BY ts
LIMIT 8;

SELECT
  'sanhedrin_nonpass_missing_cause_samples' AS section,
  id,
  ts,
  agent,
  task_id,
  status,
  substr(coalesce(notes, ''), 1, 180) AS sample
FROM iterations
WHERE agent = 'sanhedrin'
  AND status <> 'pass'
  AND coalesce(trim(error_msg), '') = ''
  AND coalesce(trim(validation_result), '') = ''
ORDER BY ts
LIMIT 8;
