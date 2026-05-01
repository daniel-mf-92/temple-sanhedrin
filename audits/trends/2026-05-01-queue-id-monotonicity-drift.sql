-- Historical queue-ID monotonicity drift audit.
-- Source DB: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Run with:
--   sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-01-queue-id-monotonicity-drift.sql

.headers on
.mode column

WITH clean_rows AS (
  SELECT
    id,
    ts,
    agent,
    task_id,
    CAST(substr(task_id, 4) AS INTEGER) AS queue_num
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
    AND task_id GLOB '[CI]Q-[0-9][0-9]*'
    AND task_id NOT LIKE '%/%'
    AND task_id NOT LIKE '%,%'
    AND task_id NOT LIKE '%+%'
),
ordered_rows AS (
  SELECT
    *,
    lag(task_id) OVER (PARTITION BY agent ORDER BY id) AS prev_task_id,
    lag(queue_num) OVER (PARTITION BY agent ORDER BY id) AS prev_queue_num,
    max(queue_num) OVER (
      PARTITION BY agent
      ORDER BY id
      ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
    ) AS prior_highwater
  FROM clean_rows
)
SELECT
  'overall_monotonicity' AS section,
  agent,
  count(*) AS clean_task_rows,
  min(queue_num) AS min_queue_num,
  max(queue_num) AS max_queue_num,
  sum(CASE WHEN prev_queue_num IS NOT NULL AND queue_num < prev_queue_num THEN 1 ELSE 0 END) AS backward_steps,
  sum(CASE WHEN prior_highwater IS NOT NULL AND queue_num < prior_highwater THEN 1 ELSE 0 END) AS below_prior_highwater_rows,
  sum(CASE WHEN prev_queue_num IS NOT NULL AND queue_num = prev_queue_num THEN 1 ELSE 0 END) AS immediate_repeats
FROM ordered_rows
GROUP BY agent
ORDER BY agent;

WITH clean_rows AS (
  SELECT
    id,
    ts,
    agent,
    task_id,
    CAST(substr(task_id, 4) AS INTEGER) AS queue_num
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
    AND task_id GLOB '[CI]Q-[0-9][0-9]*'
    AND task_id NOT LIKE '%/%'
    AND task_id NOT LIKE '%,%'
    AND task_id NOT LIKE '%+%'
),
ordered_rows AS (
  SELECT
    *,
    lag(queue_num) OVER (PARTITION BY agent ORDER BY id) AS prev_queue_num,
    max(queue_num) OVER (
      PARTITION BY agent
      ORDER BY id
      ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
    ) AS prior_highwater
  FROM clean_rows
)
SELECT
  'daily_monotonicity' AS section,
  agent,
  substr(ts, 1, 10) AS day,
  count(*) AS clean_task_rows,
  sum(CASE WHEN prev_queue_num IS NOT NULL AND queue_num < prev_queue_num THEN 1 ELSE 0 END) AS backward_steps,
  sum(CASE WHEN prior_highwater IS NOT NULL AND queue_num < prior_highwater THEN 1 ELSE 0 END) AS below_prior_highwater_rows
FROM ordered_rows
GROUP BY agent, day
ORDER BY day, agent;

WITH clean_rows AS (
  SELECT
    id,
    ts,
    agent,
    task_id,
    CAST(substr(task_id, 4) AS INTEGER) AS queue_num
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
    AND task_id GLOB '[CI]Q-[0-9][0-9]*'
    AND task_id NOT LIKE '%/%'
    AND task_id NOT LIKE '%,%'
    AND task_id NOT LIKE '%+%'
),
ordered_rows AS (
  SELECT
    *,
    lag(task_id) OVER (PARTITION BY agent ORDER BY id) AS prev_task_id,
    lag(queue_num) OVER (PARTITION BY agent ORDER BY id) AS prev_queue_num,
    max(queue_num) OVER (
      PARTITION BY agent
      ORDER BY id
      ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
    ) AS prior_highwater
  FROM clean_rows
)
SELECT
  'sample_backward_steps' AS section,
  agent,
  task_id,
  queue_num,
  prev_task_id,
  prev_queue_num,
  prior_highwater,
  ts
FROM ordered_rows
WHERE prev_queue_num IS NOT NULL
  AND queue_num < prev_queue_num
ORDER BY id
LIMIT 30;

WITH clean_rows AS (
  SELECT
    ts,
    agent,
    task_id
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
    AND task_id GLOB '[CI]Q-[0-9][0-9]*'
    AND task_id NOT LIKE '%/%'
    AND task_id NOT LIKE '%,%'
    AND task_id NOT LIKE '%+%'
)
SELECT
  'repeated_task_ids' AS section,
  agent,
  task_id,
  count(*) AS uses,
  min(ts) AS first_ts,
  max(ts) AS last_ts
FROM clean_rows
GROUP BY agent, task_id
HAVING count(*) > 1
ORDER BY uses DESC, agent, task_id
LIMIT 30;

WITH clean_rows AS (
  SELECT
    id,
    ts,
    agent,
    task_id,
    CAST(substr(task_id, 4) AS INTEGER) AS queue_num
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
    AND task_id GLOB '[CI]Q-[0-9][0-9]*'
    AND task_id NOT LIKE '%/%'
    AND task_id NOT LIKE '%,%'
    AND task_id NOT LIKE '%+%'
),
ordered_rows AS (
  SELECT
    *,
    max(queue_num) OVER (
      PARTITION BY agent
      ORDER BY id
      ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
    ) AS prior_highwater
  FROM clean_rows
)
SELECT
  'largest_highwater_regressions' AS section,
  agent,
  task_id,
  queue_num,
  prior_highwater,
  prior_highwater - queue_num AS regression_size,
  ts
FROM ordered_rows
WHERE prior_highwater IS NOT NULL
  AND queue_num < prior_highwater
ORDER BY regression_size DESC, id
LIMIT 30;
