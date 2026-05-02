-- Historical Sanhedrin task taxonomy drift audit.
-- Read-only verification against:
-- /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
--
-- Usage:
-- sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-02-sanhedrin-task-taxonomy-drift.sql

.headers on
.mode column

SELECT
  COUNT(*) AS sanhedrin_rows,
  COUNT(DISTINCT task_id) AS distinct_task_ids,
  SUM(task_id IN (
    'AUDIT',
    'CLEANUP',
    'EMAIL-CHECK',
    'VM-COMPILE',
    'VM-CHECK',
    'CI-CHECK',
    'RESEARCH',
    'LIVENESS',
    'LAW-CHECK',
    'DB-CHECK'
  )) AS generic_rows,
  ROUND(
    100.0 * SUM(task_id IN (
      'AUDIT',
      'CLEANUP',
      'EMAIL-CHECK',
      'VM-COMPILE',
      'VM-CHECK',
      'CI-CHECK',
      'RESEARCH',
      'LIVENESS',
      'LAW-CHECK',
      'DB-CHECK'
    )) / COUNT(*),
    2
  ) AS generic_pct
FROM iterations
WHERE agent = 'sanhedrin';

SELECT
  task_id,
  COUNT(*) AS rows,
  SUM(status = 'pass') AS pass,
  SUM(status = 'skip') AS skip,
  SUM(status = 'fail') AS fail,
  SUM(status = 'blocked') AS blocked,
  MIN(ts) AS first_ts,
  MAX(ts) AS last_ts
FROM iterations
WHERE agent = 'sanhedrin'
GROUP BY task_id
ORDER BY rows DESC
LIMIT 30;

SELECT
  CASE
    WHEN INSTR(task_id, '-') > 0 THEN SUBSTR(task_id, 1, INSTR(task_id, '-') - 1)
    ELSE task_id
  END AS family,
  COUNT(*) AS rows,
  COUNT(DISTINCT task_id) AS unique_ids,
  SUM(status = 'pass') AS pass,
  SUM(status = 'skip') AS skip,
  SUM(status = 'fail') AS fail,
  SUM(status = 'blocked') AS blocked
FROM iterations
WHERE agent = 'sanhedrin'
GROUP BY family
ORDER BY rows DESC;

SELECT
  task_id,
  COUNT(*) AS rows,
  COUNT(DISTINCT COALESCE(files_changed, '')) AS distinct_files,
  COUNT(DISTINCT COALESCE(validation_cmd, '')) AS distinct_cmds,
  COUNT(DISTINCT COALESCE(notes, '')) AS distinct_notes
FROM iterations
WHERE agent = 'sanhedrin'
  AND task_id IN (
    'AUDIT',
    'CLEANUP',
    'EMAIL-CHECK',
    'VM-COMPILE',
    'VM-CHECK',
    'CI-CHECK',
    'RESEARCH',
    'LIVENESS',
    'LAW-CHECK',
    'DB-CHECK'
  )
GROUP BY task_id
ORDER BY rows DESC;

WITH ordered AS (
  SELECT
    id,
    task_id,
    LAG(task_id) OVER (
      ORDER BY
        CASE
          WHEN ts GLOB '[0-9]*' AND ts NOT LIKE '%T%'
            THEN DATETIME(CAST(ts AS INTEGER), 'unixepoch')
          ELSE ts
        END,
        id
    ) AS prev_task
  FROM iterations
  WHERE agent = 'sanhedrin'
)
SELECT
  task_id,
  COUNT(*) AS consecutive_repeats
FROM ordered
WHERE task_id = prev_task
GROUP BY task_id
ORDER BY consecutive_repeats DESC
LIMIT 20;

SELECT COUNT(*) AS queue_rows FROM queue;

SELECT
  COUNT(*) AS research_rows,
  SUM(trigger_task IS NULL OR TRIM(trigger_task) = '') AS research_missing_trigger,
  COUNT(DISTINCT trigger_task) AS distinct_research_triggers
FROM research;
