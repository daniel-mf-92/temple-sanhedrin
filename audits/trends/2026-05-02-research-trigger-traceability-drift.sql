-- Historical trend audit: research trigger-task traceability drift.
-- Source DB: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Usage:
--   sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-02-research-trigger-traceability-drift.sql

.print '== Research trigger-task traceability totals =='
WITH classified AS (
  SELECT
    r.*,
    q.id AS queue_id,
    CASE
      WHEN trigger_task GLOB 'CQ-[0-9]*' OR trigger_task GLOB 'IQ-[0-9]*' THEN 1
      ELSE 0
    END AS queue_like,
    CASE
      WHEN trigger_task LIKE '%/%'
        OR trigger_task LIKE '%,%'
        OR trigger_task LIKE '%;%'
        OR trigger_task LIKE '%:%'
        OR trigger_task LIKE '%>=%'
        OR LOWER(trigger_task) LIKE '%consecutive%'
        OR LOWER(trigger_task) LIKE '%repeat%'
      THEN 1
      ELSE 0
    END AS prose_or_compound
  FROM research r
  LEFT JOIN queue q ON q.id = r.trigger_task
)
SELECT
  COUNT(*) AS research_rows,
  SUM(queue_like) AS cq_iq_like_rows,
  SUM(queue_id IS NOT NULL) AS exact_queue_join_rows,
  SUM(queue_like AND queue_id IS NULL) AS cq_iq_like_without_queue_join,
  SUM(prose_or_compound) AS prose_or_compound_trigger_rows,
  SUM(trigger_task = 'AUDIT') AS audit_trigger_rows,
  MIN(ts) AS first_ts,
  MAX(ts) AS last_ts
FROM classified;

.print ''
.print '== Trigger-task shape counts =='
WITH classified AS (
  SELECT
    CASE
      WHEN trigger_task = 'AUDIT' THEN 'audit_sentinel'
      WHEN trigger_task GLOB 'CQ-[0-9]*' THEN 'single_cq'
      WHEN trigger_task GLOB 'IQ-[0-9]*' THEN 'single_iq'
      WHEN trigger_task LIKE '%/%' OR trigger_task LIKE '%,%' OR trigger_task LIKE '%;%' THEN 'compound_task'
      WHEN trigger_task LIKE '%:%' THEN 'agent_prefixed_or_prose'
      WHEN trigger_task LIKE '%>=%' OR LOWER(trigger_task) LIKE '%consecutive%' OR LOWER(trigger_task) LIKE '%repeat%' THEN 'threshold_or_repeat_prose'
      ELSE 'other'
    END AS trigger_shape,
    ts
  FROM research
)
SELECT
  trigger_shape,
  COUNT(*) AS rows,
  MIN(ts) AS first_ts,
  MAX(ts) AS last_ts
FROM classified
GROUP BY trigger_shape
ORDER BY rows DESC, trigger_shape;

.print ''
.print '== Top repeated trigger_task values =='
SELECT
  trigger_task,
  COUNT(*) AS rows,
  MIN(ts) AS first_ts,
  MAX(ts) AS last_ts
FROM research
GROUP BY trigger_task
HAVING rows >= 4
ORDER BY rows DESC, trigger_task
LIMIT 30;

.print ''
.print '== Research trigger rows by day =='
WITH classified AS (
  SELECT
    DATE(ts) AS day,
    CASE
      WHEN trigger_task GLOB 'CQ-[0-9]*' OR trigger_task GLOB 'IQ-[0-9]*' THEN 1
      ELSE 0
    END AS queue_like,
    CASE
      WHEN trigger_task LIKE '%/%'
        OR trigger_task LIKE '%,%'
        OR trigger_task LIKE '%;%'
        OR trigger_task LIKE '%:%'
        OR trigger_task LIKE '%>=%'
        OR LOWER(trigger_task) LIKE '%consecutive%'
        OR LOWER(trigger_task) LIKE '%repeat%'
      THEN 1
      ELSE 0
    END AS prose_or_compound
  FROM research
  WHERE ts LIKE '____-__-__T__:__:__%'
)
SELECT
  day,
  COUNT(*) AS research_rows,
  SUM(queue_like) AS queue_like_rows,
  SUM(prose_or_compound) AS prose_or_compound_rows
FROM classified
GROUP BY day
ORDER BY day;

.print ''
.print '== Research rows with no queue-table materialization =='
SELECT
  COUNT(*) AS queue_table_rows
FROM queue;

.print ''
.print '== Recent non-normal trigger examples =='
SELECT
  ts,
  trigger_task,
  SUBSTR(topic, 1, 70) AS topic_excerpt
FROM research
WHERE NOT (trigger_task GLOB 'CQ-[0-9]*' OR trigger_task GLOB 'IQ-[0-9]*')
ORDER BY ts DESC
LIMIT 20;
