-- Historical Sanhedrin skip-saturation drift audit.
-- Source DB: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Run with:
--   sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-01-sanhedrin-skip-saturation-drift.sql

.headers on
.mode column

SELECT
  'status_mix' AS section,
  status,
  count(*) AS rows,
  round(count(*) * 100.0 / (SELECT count(*) FROM iterations), 1) AS pct_all_rows
FROM iterations
GROUP BY status
ORDER BY rows DESC;

SELECT
  'agent_status_mix' AS section,
  agent,
  status,
  count(*) AS rows,
  round(count(*) * 100.0 / sum(count(*)) OVER (PARTITION BY agent), 1) AS pct_agent_rows
FROM iterations
GROUP BY agent, status
ORDER BY agent, rows DESC;

SELECT
  'status_structured_field_gaps' AS section,
  status,
  count(*) AS rows,
  sum(error_msg IS NULL OR error_msg = '') AS missing_error_msg,
  sum(validation_result IS NULL OR validation_result = '') AS missing_validation_result,
  sum(validation_cmd IS NULL OR validation_cmd = '') AS missing_validation_cmd
FROM iterations
GROUP BY status
ORDER BY rows DESC;

SELECT
  'daily_sanhedrin_skip_rate' AS section,
  substr(ts, 1, 10) AS day,
  count(*) AS rows,
  sum(status = 'skip') AS skip_rows,
  round(sum(status = 'skip') * 100.0 / count(*), 1) AS skip_pct,
  sum(status = 'fail') AS fail_rows,
  sum(status = 'blocked') AS blocked_rows
FROM iterations
WHERE agent = 'sanhedrin'
GROUP BY day
ORDER BY day;

SELECT
  'skip_reason_classes' AS section,
  CASE
    WHEN notes LIKE '%MARTA_GOOGLE_CLIENT%' THEN 'missing_marta_google_credentials'
    WHEN task_id LIKE 'CI-%' AND lower(notes) LIKE '%no run%' THEN 'ci_no_runs'
    WHEN lower(notes) LIKE '%unavailable%' THEN 'other_unavailable'
    ELSE 'other'
  END AS skip_class,
  count(*) AS rows,
  min(ts) AS first_ts,
  max(ts) AS last_ts,
  count(DISTINCT task_id) AS task_ids
FROM iterations
WHERE agent = 'sanhedrin'
  AND status = 'skip'
GROUP BY skip_class
ORDER BY rows DESC;

SELECT
  'skip_task_saturation' AS section,
  task_id,
  count(*) AS rows,
  sum(status = 'skip') AS skip_rows,
  min(ts) AS first_ts,
  max(ts) AS last_ts,
  count(DISTINCT substr(coalesce(notes, ''), 1, 80)) AS note_prefixes
FROM iterations
WHERE agent = 'sanhedrin'
GROUP BY task_id
HAVING skip_rows > 0
ORDER BY skip_rows DESC
LIMIT 20;

SELECT
  'high_repeat_status_groups' AS section,
  agent,
  task_id,
  status,
  count(*) AS rows,
  count(DISTINCT coalesce(error_msg, '')) AS distinct_errors,
  count(DISTINCT coalesce(validation_result, '')) AS distinct_results,
  count(DISTINCT coalesce(notes, '')) AS distinct_notes
FROM iterations
GROUP BY agent, task_id, status
HAVING rows >= 10
ORDER BY rows DESC
LIMIT 30;
