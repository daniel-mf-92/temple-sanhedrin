-- Historical builder status taxonomy collapse drift audit.
-- Source DB: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Run with:
--   sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-01-builder-status-taxonomy-collapse-drift.sql

.headers on
.mode column

SELECT
  'status_by_agent' AS section,
  agent,
  status,
  count(*) AS rows,
  min(ts) AS first_ts,
  max(ts) AS last_ts
FROM iterations
GROUP BY agent, status
ORDER BY agent, status;

WITH builder AS (
  SELECT
    agent,
    status,
    ' ' || replace(replace(replace(replace(replace(replace(
      lower(coalesce(validation_result, '') || ' ' || coalesce(notes, '')),
      '-', ' '), '>', ' '), ':', ' '), ';', ' '), ',', ' '), '.', ' ') || ' ' AS evidence_text
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
)
SELECT
  'builder_pass_caveat_text' AS section,
  agent,
  count(*) AS rows,
  sum(CASE WHEN evidence_text LIKE '% red %' THEN 1 ELSE 0 END) AS red_word_rows,
  sum(CASE WHEN evidence_text LIKE '% timed out %' THEN 1 ELSE 0 END) AS timed_out_rows,
  sum(CASE WHEN evidence_text LIKE '% blocked %' THEN 1 ELSE 0 END) AS blocked_word_rows,
  sum(CASE WHEN evidence_text LIKE '% skipped %' THEN 1 ELSE 0 END) AS skipped_word_rows
FROM builder
GROUP BY agent
ORDER BY agent;

SELECT
  'null_aux_fields' AS section,
  agent,
  count(*) AS rows,
  sum(CASE WHEN validation_result IS NULL OR trim(validation_result) = '' THEN 1 ELSE 0 END) AS empty_validation_result,
  sum(CASE WHEN error_msg IS NULL OR trim(error_msg) = '' THEN 1 ELSE 0 END) AS empty_error_msg,
  sum(CASE WHEN notes IS NULL OR trim(notes) = '' THEN 1 ELSE 0 END) AS empty_notes,
  sum(CASE WHEN duration_sec IS NULL THEN 1 ELSE 0 END) AS null_duration_sec
FROM iterations
GROUP BY agent
ORDER BY agent;

SELECT
  'daily_status_diversity' AS section,
  agent,
  substr(ts, 1, 10) AS day,
  count(*) AS rows,
  count(DISTINCT status) AS distinct_statuses,
  group_concat(DISTINCT status) AS statuses
FROM iterations
GROUP BY agent, day
ORDER BY day DESC, agent
LIMIT 60;

SELECT
  'builder_pass_rows_with_caveat_text' AS section,
  agent,
  task_id,
  ts,
  substr(validation_result || ' ' || notes, 1, 220) AS evidence_excerpt
FROM iterations
WHERE agent IN ('modernization', 'inference')
  AND status = 'pass'
  AND (
    lower(coalesce(validation_result, '') || ' ' || coalesce(notes, '')) LIKE '%timed out%'
    OR lower(coalesce(validation_result, '') || ' ' || coalesce(notes, '')) LIKE '%blocked%'
    OR lower(coalesce(validation_result, '') || ' ' || coalesce(notes, '')) LIKE '%skipped%'
  )
ORDER BY id DESC
LIMIT 20;
