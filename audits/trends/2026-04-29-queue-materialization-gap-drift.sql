-- Historical queue materialization gap audit for temple-central.db.
-- Read-only query pack used by:
-- audits/trends/2026-04-29-queue-materialization-gap-drift.md

.headers on
.mode column

SELECT
  'iterations' AS table_name,
  count(*) AS rows
FROM iterations
UNION ALL
SELECT
  'queue' AS table_name,
  count(*) AS rows
FROM queue
UNION ALL
SELECT
  'violations' AS table_name,
  count(*) AS rows
FROM violations
UNION ALL
SELECT
  'research' AS table_name,
  count(*) AS rows
FROM research;

SELECT
  agent,
  count(*) AS rows,
  count(DISTINCT task_id) AS distinct_task_ids,
  min(ts) AS first_ts,
  max(ts) AS last_ts,
  min(task_id) AS min_task_id,
  max(task_id) AS max_task_id
FROM iterations
WHERE agent IN ('modernization', 'inference')
GROUP BY agent
ORDER BY agent;

WITH RECURSIVE split(id, agent, task_id, rest, token) AS (
  SELECT
    id,
    agent,
    task_id,
    task_id || '/',
    NULL
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
  UNION ALL
  SELECT
    id,
    agent,
    task_id,
    substr(rest, instr(rest, '/') + 1),
    substr(rest, 1, instr(rest, '/') - 1)
  FROM split
  WHERE rest <> ''
    AND instr(rest, '/') > 0
),
tokens AS (
  SELECT
    id,
    agent,
    task_id,
    token
  FROM split
  WHERE token IS NOT NULL
    AND token <> ''
)
SELECT
  agent,
  count(*) AS task_token_rows,
  count(DISTINCT token) AS distinct_task_tokens,
  min(token) AS min_task_token,
  max(token) AS max_task_token
FROM tokens
GROUP BY agent
ORDER BY agent;

WITH RECURSIVE split(id, agent, task_id, rest, token) AS (
  SELECT
    id,
    agent,
    task_id,
    task_id || '/',
    NULL
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
  UNION ALL
  SELECT
    id,
    agent,
    task_id,
    substr(rest, instr(rest, '/') + 1),
    substr(rest, 1, instr(rest, '/') - 1)
  FROM split
  WHERE rest <> ''
    AND instr(rest, '/') > 0
),
tokens AS (
  SELECT
    agent,
    token,
    count(*) AS rows
  FROM split
  WHERE token IS NOT NULL
    AND token <> ''
  GROUP BY agent, token
)
SELECT
  agent,
  count(*) AS task_ids,
  sum(rows > 1) AS repeated_task_ids,
  max(rows) AS max_rows_per_task,
  round(avg(rows), 2) AS avg_rows_per_task
FROM tokens
GROUP BY agent
ORDER BY agent;

WITH RECURSIVE split(id, agent, task_id, rest, token) AS (
  SELECT
    id,
    agent,
    task_id,
    task_id || '/',
    NULL
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
  UNION ALL
  SELECT
    id,
    agent,
    task_id,
    substr(rest, instr(rest, '/') + 1),
    substr(rest, 1, instr(rest, '/') - 1)
  FROM split
  WHERE rest <> ''
    AND instr(rest, '/') > 0
),
tokens AS (
  SELECT
    agent,
    token,
    count(*) AS rows,
    min(id) AS first_id,
    max(id) AS last_id
  FROM split
  WHERE token IS NOT NULL
    AND token <> ''
  GROUP BY agent, token
)
SELECT
  agent,
  token,
  rows,
  first_id,
  last_id
FROM tokens
WHERE rows >= 4
ORDER BY rows DESC, agent, token
LIMIT 30;

SELECT
  agent,
  count(*) AS rows,
  sum(task_id GLOB '*/*') AS slash_task_rows,
  count(DISTINCT CASE WHEN task_id GLOB '*/*' THEN task_id END) AS slash_task_ids,
  sum(task_id NOT GLOB 'CQ-[0-9]*'
      AND task_id NOT GLOB 'IQ-[0-9]*'
      AND task_id NOT GLOB '*/*') AS non_queue_shape_rows
FROM iterations
WHERE agent IN ('modernization', 'inference')
GROUP BY agent
ORDER BY agent;

SELECT
  id,
  ts,
  agent,
  task_id,
  status
FROM iterations
WHERE agent IN ('modernization', 'inference')
  AND task_id GLOB '*/*'
ORDER BY id DESC
LIMIT 40;

SELECT
  name,
  seq
FROM sqlite_sequence
ORDER BY name;
