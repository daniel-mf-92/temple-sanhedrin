-- Historical drift audit: North Star Discipline evidence blindspot in temple-central.db.
-- Source DB: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Usage:
--   sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-02-north-star-evidence-blindspot.sql

.print '== Builder North Star evidence terms =='
WITH builder_rows AS (
  SELECT
    agent,
    status,
    LOWER(
      COALESCE(validation_cmd, '') || ' ' ||
      COALESCE(validation_result, '') || ' ' ||
      COALESCE(notes, '')
    ) AS evidence_text
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
)
SELECT
  agent,
  COUNT(*) AS rows,
  SUM(status = 'pass') AS pass_rows,
  SUM(evidence_text LIKE '%north-star-e2e%') AS north_star_e2e_mentions,
  SUM(evidence_text LIKE '%north_star%') AS north_star_underscore_mentions,
  SUM(evidence_text LIKE '%north star%') AS north_star_phrase_mentions
FROM builder_rows
GROUP BY agent
ORDER BY agent;

.print ''
.print '== Builder file/path evidence shape =='
WITH builder_rows AS (
  SELECT
    agent,
    status,
    LOWER(COALESCE(files_changed, '')) AS files_changed
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
)
SELECT
  agent,
  COUNT(*) AS pass_rows,
  SUM(files_changed LIKE '%master_tasks.md%') AS master_tasks_rows,
  SUM(files_changed LIKE '%north_star.md%') AS north_star_file_rows,
  SUM(files_changed LIKE '%docs/%' OR files_changed LIKE '%readme%') AS docs_rows,
  SUM(files_changed LIKE '%automation/%' OR files_changed LIKE '%tests/%') AS host_validation_rows,
  SUM(
    files_changed LIKE '%src/%' OR
    files_changed LIKE '%kernel/%' OR
    files_changed LIKE '%adam/%' OR
    files_changed LIKE '%compiler/%' OR
    files_changed LIKE '%apps/%'
  ) AS core_path_rows
FROM builder_rows
WHERE status = 'pass'
GROUP BY agent
ORDER BY agent;

.print ''
.print '== Zero-line builder pass rows =='
SELECT
  agent,
  COUNT(*) AS zero_line_pass_rows,
  MIN(ts) AS first_ts,
  MAX(ts) AS last_ts,
  GROUP_CONCAT(task_id, ', ') AS task_ids
FROM (
  SELECT *
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
    AND status = 'pass'
    AND lines_added = 0
    AND lines_removed = 0
  ORDER BY ts
)
GROUP BY agent
ORDER BY agent;

.print ''
.print '== Repeated builder task IDs =='
SELECT
  agent,
  task_id,
  COUNT(*) AS repeats,
  MIN(ts) AS first_ts,
  MAX(ts) AS last_ts
FROM iterations
WHERE agent IN ('modernization', 'inference')
GROUP BY agent, task_id
HAVING repeats >= 3
ORDER BY repeats DESC, agent, task_id
LIMIT 30;

.print ''
.print '== Daily builder pass rows and evidence blanks =='
SELECT
  DATE(ts) AS day,
  agent,
  COUNT(*) AS rows,
  SUM(status = 'pass') AS pass_rows,
  SUM(COALESCE(validation_cmd, '') = '') AS blank_cmd,
  SUM(COALESCE(validation_result, '') = '') AS blank_result
FROM iterations
WHERE agent IN ('modernization', 'inference')
  AND ts LIKE '____-__-__T__:__:__%'
GROUP BY DATE(ts), agent
ORDER BY day, agent;
