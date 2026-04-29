-- Historical research trigger traceability drift audit.
-- Read-only query pack for /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db

.headers on
.mode column

SELECT
  COUNT(*) AS research_rows,
  SUM(trigger_task IS NULL OR trim(trigger_task) = '') AS blank_trigger,
  SUM(references_urls IS NULL OR trim(references_urls) = '') AS blank_refs,
  SUM(findings IS NULL OR trim(findings) = '') AS blank_findings,
  MIN(ts) AS first_ts,
  MAX(ts) AS last_ts
FROM research;

WITH shaped AS (
  SELECT
    *,
    CASE
      WHEN substr(trigger_task, 1, 3) IN ('CQ-', 'IQ-')
       AND substr(trigger_task, 4) GLOB '[0-9]*'
       AND substr(trigger_task, 4) NOT GLOB '*[^0-9]*' THEN 'single_queue'
      WHEN trigger_task LIKE '%CQ-%' OR trigger_task LIKE '%IQ-%' THEN 'mixed_queue_text'
      ELSE 'non_queue_text'
    END AS trigger_shape
  FROM research
)
SELECT
  trigger_shape,
  COUNT(*) AS rows,
  COUNT(DISTINCT trigger_task) AS distinct_triggers,
  SUM(references_urls IS NULL OR trim(references_urls) = '') AS blank_refs
FROM shaped
GROUP BY trigger_shape
ORDER BY trigger_shape;

WITH single_queue AS (
  SELECT id, ts, topic, trigger_task
  FROM research
  WHERE substr(trigger_task, 1, 3) IN ('CQ-', 'IQ-')
    AND substr(trigger_task, 4) GLOB '[0-9]*'
    AND substr(trigger_task, 4) NOT GLOB '*[^0-9]*'
),
matched AS (
  SELECT
    r.*,
    (SELECT COUNT(*) FROM iterations i WHERE i.task_id = r.trigger_task) AS exact_rows,
    (SELECT COUNT(*) FROM iterations i WHERE i.task_id = r.trigger_task AND i.ts <= r.ts) AS prior_exact_rows
  FROM single_queue r
)
SELECT
  COUNT(*) AS single_queue_rows,
  SUM(exact_rows = 0) AS no_exact_iteration,
  SUM(prior_exact_rows = 0) AS no_prior_exact_iteration,
  SUM(exact_rows > 0 AND prior_exact_rows = 0) AS only_future_match
FROM matched;

WITH single_queue AS (
  SELECT id, ts, topic, trigger_task
  FROM research
  WHERE substr(trigger_task, 1, 3) IN ('CQ-', 'IQ-')
    AND substr(trigger_task, 4) GLOB '[0-9]*'
    AND substr(trigger_task, 4) NOT GLOB '*[^0-9]*'
),
matched AS (
  SELECT
    r.*,
    (SELECT COUNT(*) FROM iterations i WHERE i.task_id = r.trigger_task) AS exact_rows,
    (SELECT COUNT(*) FROM iterations i WHERE i.task_id = r.trigger_task AND i.ts <= r.ts) AS prior_exact_rows
  FROM single_queue r
)
SELECT
  id,
  ts,
  topic,
  trigger_task,
  exact_rows,
  prior_exact_rows
FROM matched
WHERE exact_rows = 0 OR prior_exact_rows = 0
ORDER BY id
LIMIT 30;

WITH trigger_tokens AS (
  SELECT
    id,
    ts,
    topic,
    trigger_task,
    replace(replace(replace(trigger_task, ',', '/'), ';', '/'), ' ', '/') AS normalized
  FROM research
),
split(id, ts, topic, trigger_task, token, rest) AS (
  SELECT id, ts, topic, trigger_task, '', normalized || '/'
  FROM trigger_tokens
  UNION ALL
  SELECT
    id,
    ts,
    topic,
    trigger_task,
    substr(rest, 1, instr(rest, '/') - 1),
    substr(rest, instr(rest, '/') + 1)
  FROM split
  WHERE rest <> ''
),
tokens AS (
  SELECT id, ts, topic, trigger_task, token
  FROM split
  WHERE token <> ''
    AND (token GLOB 'CQ-[0-9]*' OR token GLOB 'IQ-[0-9]*')
)
SELECT
  COUNT(*) AS token_rows,
  COUNT(DISTINCT id) AS research_rows_with_tokens,
  COUNT(DISTINCT token) AS distinct_tokens,
  SUM(token NOT IN (SELECT task_id FROM iterations WHERE agent IN ('modernization', 'inference'))) AS tokens_without_exact_iteration_match
FROM tokens;

SELECT
  trigger_task,
  COUNT(*) AS rows,
  COUNT(DISTINCT topic) AS topics,
  SUM(references_urls IS NULL OR trim(references_urls) = '') AS blank_refs,
  MIN(ts) AS first_ts,
  MAX(ts) AS last_ts
FROM research
GROUP BY trigger_task
HAVING COUNT(*) >= 5
ORDER BY rows DESC, trigger_task
LIMIT 25;

WITH sequenced AS (
  SELECT
    id,
    ts,
    topic,
    trigger_task,
    LAG(trigger_task) OVER (ORDER BY id) AS prev_trigger,
    LAG(ts) OVER (ORDER BY id) AS prev_ts
  FROM research
)
SELECT
  COUNT(*) AS rows_after_first,
  SUM(trigger_task = prev_trigger) AS same_as_previous,
  SUM(trigger_task = prev_trigger AND (julianday(ts) - julianday(prev_ts)) * 86400 < 600) AS same_previous_under_10m
FROM sequenced
WHERE prev_trigger IS NOT NULL;

SELECT
  substr(ts, 1, 10) AS day,
  COUNT(*) AS rows,
  COUNT(DISTINCT topic) AS topics,
  COUNT(DISTINCT trigger_task) AS triggers,
  SUM(references_urls IS NULL OR trim(references_urls) = '') AS blank_refs
FROM research
GROUP BY day
ORDER BY day;
