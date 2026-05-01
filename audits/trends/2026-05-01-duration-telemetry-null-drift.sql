-- Historical duration telemetry null drift audit.
-- Source DB: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Run with:
--   sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-01-duration-telemetry-null-drift.sql

.headers on
.mode column

SELECT
  'overall_duration_coverage' AS section,
  agent,
  count(*) AS rows,
  sum(duration_sec IS NULL) AS null_duration_rows,
  sum(duration_sec IS NOT NULL) AS populated_duration_rows,
  min(duration_sec) AS min_duration_sec,
  max(duration_sec) AS max_duration_sec,
  sum(CASE WHEN duration_sec > 1500 THEN 1 ELSE 0 END) AS over_25_min_rows
FROM iterations
GROUP BY agent
ORDER BY agent;

SELECT
  'status_duration_coverage' AS section,
  agent,
  status,
  count(*) AS rows,
  sum(duration_sec IS NULL) AS null_duration_rows,
  sum(CASE WHEN coalesce(files_changed, '') <> '' THEN 1 ELSE 0 END) AS rows_with_files,
  sum(coalesce(lines_added, 0)) AS lines_added,
  sum(coalesce(lines_removed, 0)) AS lines_removed
FROM iterations
GROUP BY agent, status
ORDER BY agent, status;

SELECT
  'daily_duration_gaps' AS section,
  substr(ts, 1, 10) AS day,
  agent,
  count(*) AS rows,
  sum(duration_sec IS NULL) AS null_duration_rows,
  sum(CASE WHEN status = 'pass' THEN 1 ELSE 0 END) AS pass_rows,
  sum(CASE WHEN status IN ('fail', 'blocked') THEN 1 ELSE 0 END) AS fail_or_blocked_rows
FROM iterations
GROUP BY day, agent
HAVING null_duration_rows > 0
ORDER BY day DESC, agent
LIMIT 40;

SELECT
  'repeat_task_without_duration' AS section,
  agent,
  task_id,
  count(*) AS repeats,
  min(ts) AS first_ts,
  max(ts) AS last_ts,
  sum(duration_sec IS NULL) AS null_duration_rows,
  sum(CASE WHEN status IN ('fail', 'blocked') THEN 1 ELSE 0 END) AS fail_or_blocked_rows
FROM iterations
GROUP BY agent, task_id
HAVING repeats >= 5
   AND null_duration_rows = repeats
ORDER BY repeats DESC, agent, task_id
LIMIT 30;

SELECT
  'law7_surrogate_rows_without_duration' AS section,
  task_id,
  status,
  count(*) AS rows,
  min(ts) AS first_ts,
  max(ts) AS last_ts,
  sum(duration_sec IS NULL) AS null_duration_rows
FROM iterations
WHERE agent = 'sanhedrin'
  AND task_id IN ('LIVENESS', 'AUDIT', 'LAW-CHECK')
GROUP BY task_id, status
ORDER BY task_id, status;

SELECT
  'latest_rows_without_duration' AS section,
  id,
  ts,
  agent,
  task_id,
  status,
  substr(validation_cmd, 1, 120) AS validation_cmd,
  substr(notes, 1, 120) AS notes
FROM iterations
WHERE duration_sec IS NULL
ORDER BY id DESC
LIMIT 20;
