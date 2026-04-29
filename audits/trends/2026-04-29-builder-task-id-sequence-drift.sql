-- Historical builder task-id sequence drift audit.
-- Source DB: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Scope: read-only aggregation over iterations rows; no TempleOS/holyc-inference files modified.

.headers on
.mode column

SELECT
  COUNT(*) AS iterations,
  MIN(ts) AS first_ts,
  MAX(ts) AS last_ts
FROM iterations;

SELECT
  agent,
  COUNT(*) AS rows,
  SUM(
    task_id NOT GLOB CASE
      WHEN agent = 'modernization' THEN 'CQ-[0-9]*'
      ELSE 'IQ-[0-9]*'
    END
  ) AS noncanonical,
  SUM(
    task_id LIKE '%/%'
    OR task_id LIKE '%,%'
    OR task_id LIKE '%+%'
    OR task_id LIKE '% and %'
  ) AS multiplexed,
  COUNT(DISTINCT task_id) AS distinct_tasks
FROM iterations
WHERE agent IN ('modernization', 'inference')
GROUP BY agent
ORDER BY agent;

WITH dup AS (
  SELECT agent, task_id, COUNT(*) AS n
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
  GROUP BY agent, task_id
  HAVING n > 1
)
SELECT
  agent,
  COUNT(*) AS duplicate_task_ids,
  SUM(n) AS rows_on_duplicate_ids,
  MAX(n) AS max_reuse
FROM dup
GROUP BY agent
ORDER BY agent;

WITH multi AS (
  SELECT
    agent,
    task_id,
    1 + length(task_id) - length(replace(replace(task_id, ',', '/'), '/', '')) AS parts
  FROM iterations
  WHERE agent = 'modernization'
    AND (task_id LIKE '%/%' OR task_id LIKE '%,%')
)
SELECT
  COUNT(*) AS multiplexed_rows,
  SUM(parts) AS apparent_task_mentions,
  MAX(parts) AS max_tasks_in_row
FROM multi;

WITH parsed AS (
  SELECT
    id,
    agent,
    task_id,
    ts,
    CASE
      WHEN task_id GLOB 'CQ-[0-9]*'
        AND instr(substr(task_id, 4), '/') = 0
        AND instr(substr(task_id, 4), ',') = 0
      THEN CAST(substr(task_id, 4) AS INTEGER)
      WHEN task_id GLOB 'IQ-[0-9]*'
        AND instr(substr(task_id, 4), '/') = 0
        AND instr(substr(task_id, 4), ',') = 0
      THEN CAST(substr(task_id, 4) AS INTEGER)
    END AS num
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
),
ordered AS (
  SELECT
    *,
    LAG(num) OVER (PARTITION BY agent ORDER BY ts, id) AS prev_num
  FROM parsed
  WHERE num IS NOT NULL
)
SELECT
  agent,
  COUNT(*) AS numeric_rows,
  MIN(num) AS min_id,
  MAX(num) AS max_id,
  SUM(num < prev_num) AS backwards,
  SUM(num = prev_num) AS repeats_adjacent,
  SUM(num > prev_num + 1) AS forward_gaps
FROM ordered
GROUP BY agent
ORDER BY agent;

WITH parsed AS (
  SELECT
    id,
    agent,
    task_id,
    ts,
    CASE
      WHEN task_id GLOB 'CQ-[0-9]*'
        AND instr(substr(task_id, 4), '/') = 0
        AND instr(substr(task_id, 4), ',') = 0
      THEN CAST(substr(task_id, 4) AS INTEGER)
      WHEN task_id GLOB 'IQ-[0-9]*'
        AND instr(substr(task_id, 4), '/') = 0
        AND instr(substr(task_id, 4), ',') = 0
      THEN CAST(substr(task_id, 4) AS INTEGER)
    END AS num
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
),
ordered AS (
  SELECT
    *,
    LAG(num) OVER (PARTITION BY agent ORDER BY ts, id) AS prev_num
  FROM parsed
  WHERE num IS NOT NULL
)
SELECT
  agent,
  substr(ts, 1, 10) AS day,
  COUNT(*) AS numeric_rows,
  SUM(num < prev_num) AS backwards,
  SUM(num = prev_num) AS adjacent_repeats,
  SUM(num > prev_num + 1) AS forward_gaps
FROM ordered
GROUP BY agent, substr(ts, 1, 10)
ORDER BY day, agent;

SELECT
  agent,
  task_id,
  COUNT(*) AS n,
  MIN(ts) AS first_ts,
  MAX(ts) AS last_ts
FROM iterations
WHERE agent IN ('modernization', 'inference')
GROUP BY agent, task_id
HAVING n > 1
ORDER BY n DESC, agent, task_id
LIMIT 25;

SELECT
  task_id,
  COUNT(*) AS n
FROM iterations
WHERE agent = 'modernization'
  AND (task_id LIKE '%/%' OR task_id LIKE '%,%')
GROUP BY task_id
ORDER BY n DESC, task_id
LIMIT 20;

WITH parsed AS (
  SELECT
    id,
    agent,
    task_id,
    ts,
    CASE
      WHEN task_id GLOB 'CQ-[0-9]*'
        AND instr(substr(task_id, 4), '/') = 0
        AND instr(substr(task_id, 4), ',') = 0
      THEN CAST(substr(task_id, 4) AS INTEGER)
      WHEN task_id GLOB 'IQ-[0-9]*'
        AND instr(substr(task_id, 4), '/') = 0
        AND instr(substr(task_id, 4), ',') = 0
      THEN CAST(substr(task_id, 4) AS INTEGER)
    END AS num
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
),
ordered AS (
  SELECT
    *,
    LAG(num) OVER (PARTITION BY agent ORDER BY ts, id) AS prev_num,
    LAG(task_id) OVER (PARTITION BY agent ORDER BY ts, id) AS prev_task,
    LAG(ts) OVER (PARTITION BY agent ORDER BY ts, id) AS prev_ts
  FROM parsed
  WHERE num IS NOT NULL
)
SELECT
  agent,
  prev_ts,
  prev_task,
  ts,
  task_id,
  prev_num,
  num
FROM ordered
WHERE num < prev_num
ORDER BY ts
LIMIT 30;
