-- Historical compound task-id traceability drift audit.
-- Source DB: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Run with:
--   sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-01-compound-task-id-traceability-drift.sql

.headers on
.mode column

WITH rows AS (
  SELECT
    id,
    ts,
    agent,
    task_id,
    status,
    files_changed,
    CASE
      WHEN task_id LIKE '%/%' OR task_id LIKE '%,%' OR task_id LIKE '%+%'
      THEN 1 ELSE 0
    END AS compound_task_id
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
)
SELECT
  'overall_compound_task_ids' AS section,
  agent,
  count(*) AS rows,
  sum(compound_task_id) AS compound_rows,
  printf('%.1f%%', 100.0 * sum(compound_task_id) / count(*)) AS compound_pct,
  max(length(task_id)) AS max_task_id_len
FROM rows
GROUP BY agent
ORDER BY agent;

WITH flagged AS (
  SELECT
    id,
    ts,
    task_id,
    length(task_id) - length(replace(task_id, '/', ''))
      + length(task_id) - length(replace(task_id, ',', ''))
      + length(task_id) - length(replace(task_id, '+', ''))
      + 1 AS component_refs
  FROM iterations
  WHERE agent = 'modernization'
    AND (task_id LIKE '%/%' OR task_id LIKE '%,%' OR task_id LIKE '%+%')
)
SELECT
  'compound_component_shape' AS section,
  count(*) AS compound_rows,
  sum(component_refs) AS component_refs,
  max(component_refs) AS max_components,
  printf('%.2f', avg(component_refs)) AS avg_components
FROM flagged;

SELECT
  'daily_modernization_compound_rate' AS section,
  substr(ts, 1, 10) AS day,
  count(*) AS rows,
  sum(task_id LIKE '%/%' OR task_id LIKE '%,%' OR task_id LIKE '%+%') AS compound_rows,
  printf(
    '%.1f%%',
    100.0 * sum(task_id LIKE '%/%' OR task_id LIKE '%,%' OR task_id LIKE '%+%') / count(*)
  ) AS compound_pct
FROM iterations
WHERE agent = 'modernization'
GROUP BY day
HAVING compound_rows > 0
ORDER BY day;

SELECT
  'latest_compound_rows' AS section,
  id,
  ts,
  task_id,
  status,
  substr(files_changed, 1, 180) AS files_changed
FROM iterations
WHERE agent = 'modernization'
  AND (task_id LIKE '%/%' OR task_id LIKE '%,%' OR task_id LIKE '%+%')
ORDER BY id DESC
LIMIT 20;

SELECT
  'repeated_compound_ids' AS section,
  task_id,
  count(*) AS rows,
  min(ts) AS first_ts,
  max(ts) AS last_ts
FROM iterations
WHERE agent = 'modernization'
  AND (task_id LIKE '%/%' OR task_id LIKE '%,%' OR task_id LIKE '%+%')
GROUP BY task_id
HAVING count(*) > 1
ORDER BY rows DESC, task_id
LIMIT 20;

SELECT
  'queue_table_cardinality' AS section,
  count(*) AS queue_rows
FROM queue;

WITH slash_parts(iter_id, iter_ts, task_id, component, rest) AS (
  SELECT
    id,
    ts,
    task_id,
    '',
    task_id || '/'
  FROM iterations
  WHERE agent = 'modernization'
    AND task_id LIKE '%/%'
  UNION ALL
  SELECT
    iter_id,
    iter_ts,
    task_id,
    substr(rest, 1, instr(rest, '/') - 1),
    substr(rest, instr(rest, '/') + 1)
  FROM slash_parts
  WHERE rest <> ''
),
clean_parts AS (
  SELECT iter_id, iter_ts, task_id, component
  FROM slash_parts
  WHERE component <> ''
),
joined AS (
  SELECT
    c.iter_id,
    c.iter_ts,
    c.task_id,
    c.component,
    q.status AS queue_status
  FROM clean_parts c
  LEFT JOIN queue q ON q.id = c.component
)
SELECT
  'slash_component_queue_join' AS section,
  count(*) AS component_refs,
  sum(queue_status IS NULL) AS missing_queue_refs,
  sum(queue_status = 'done') AS done_refs,
  sum(queue_status IN ('pending', 'in_progress', 'blocked', 'skipped')) AS open_refs
FROM joined;
