-- Historical drift audit: research topic normalization churn.
-- Read-only verification:
-- sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-02-research-topic-normalization-churn.sql

.headers on
.mode column

-- 1. Overall research table concentration in repeat/stuck-loop topics.
WITH classified AS (
  SELECT
    *,
    CASE
      WHEN lower(topic) LIKE '%repeat-task%'
        OR lower(topic) LIKE '%repeat task%'
        OR lower(topic) LIKE '%stuck%'
        OR lower(topic) LIKE '%loop%'
        OR lower(topic) LIKE '%streak%' THEN 1
      ELSE 0
    END AS is_repeat_loop
  FROM research
)
SELECT
  COUNT(*) AS total_rows,
  SUM(is_repeat_loop) AS repeat_loop_rows,
  ROUND(100.0 * SUM(is_repeat_loop) / COUNT(*), 1) AS repeat_loop_pct,
  SUM(CASE WHEN is_repeat_loop = 1 AND COALESCE(references_urls, '') = '' THEN 1 ELSE 0 END) AS repeat_blank_refs,
  SUM(CASE WHEN is_repeat_loop = 0 AND COALESCE(references_urls, '') = '' THEN 1 ELSE 0 END) AS other_blank_refs,
  MIN(ts) AS first_ts,
  MAX(ts) AS last_ts
FROM classified;

-- 2. Topic-family churn after lightweight normalization.
WITH normalized AS (
  SELECT
    topic,
    lower(replace(replace(replace(topic, ' ', '-'), '_', '-'), ':', '')) AS norm_topic,
    ts,
    trigger_task
  FROM research
),
families AS (
  SELECT
    CASE
      WHEN norm_topic LIKE 'repeat-task-streak-remediation-v%' THEN 'repeat-task-streak-remediation-v*'
      WHEN norm_topic IN (
        'repeat-task-streak-remediation',
        'repeat-task-streak-mitigation',
        'repeat-task-streak-breakers',
        'repeat-task-streak-circuit-breakers',
        'repeat-task-streak-guardrails'
      ) THEN 'repeat-task-streak-*'
      WHEN norm_topic LIKE '%repeat-task-loop%' THEN 'repeat-task-loop-*'
      WHEN norm_topic LIKE '%stuck-loop%' THEN 'stuck-loop-*'
      ELSE norm_topic
    END AS family,
    topic,
    trigger_task,
    ts
  FROM normalized
)
SELECT
  family,
  COUNT(*) AS rows,
  COUNT(DISTINCT topic) AS distinct_topics,
  COUNT(DISTINCT trigger_task) AS distinct_triggers,
  MIN(ts) AS first_ts,
  MAX(ts) AS last_ts
FROM families
GROUP BY family
HAVING rows >= 3
ORDER BY rows DESC
LIMIT 20;

-- 3. Version-suffixed topic churn.
SELECT
  COUNT(*) AS versioned_topic_rows,
  COUNT(DISTINCT topic) AS distinct_versioned_topics,
  MIN(ts) AS first_ts,
  MAX(ts) AS last_ts
FROM research
WHERE lower(topic) GLOB '*-v[0-9]*';

SELECT
  topic,
  COUNT(*) AS rows,
  MIN(ts) AS first_ts,
  MAX(ts) AS last_ts
FROM research
WHERE lower(topic) GLOB '*-v[0-9]*'
GROUP BY topic
ORDER BY rows DESC, topic
LIMIT 20;

-- 4. Daily burst concentration.
SELECT
  date(ts) AS day,
  COUNT(*) AS research_rows,
  SUM(CASE
    WHEN lower(topic) LIKE '%repeat-task%'
      OR lower(topic) LIKE '%repeat task%'
      OR lower(topic) LIKE '%stuck%'
      OR lower(topic) LIKE '%loop%'
      OR lower(topic) LIKE '%streak%' THEN 1
    ELSE 0
  END) AS repeat_loop_rows,
  SUM(CASE WHEN COALESCE(references_urls, '') = '' THEN 1 ELSE 0 END) AS blank_refs
FROM research
GROUP BY date(ts)
ORDER BY day;

SELECT
  strftime('%Y-%m-%dT%H:00:00', ts) AS hour,
  COUNT(*) AS rows,
  SUM(CASE
    WHEN lower(topic) LIKE '%repeat-task%'
      OR lower(topic) LIKE '%repeat task%'
      OR lower(topic) LIKE '%stuck%'
      OR lower(topic) LIKE '%loop%'
      OR lower(topic) LIKE '%streak%' THEN 1
    ELSE 0
  END) AS repeat_loop_rows,
  COUNT(DISTINCT topic) AS distinct_topics,
  COUNT(DISTINCT trigger_task) AS distinct_triggers
FROM research
GROUP BY hour
ORDER BY rows DESC
LIMIT 12;

-- 5. Same-trigger research proliferation.
WITH repeat_research AS (
  SELECT
    ts,
    topic,
    trigger_task,
    references_urls
  FROM research
  WHERE lower(topic) LIKE '%repeat-task%'
    OR lower(topic) LIKE '%repeat task%'
    OR lower(topic) LIKE '%stuck%'
    OR lower(topic) LIKE '%loop%'
    OR lower(topic) LIKE '%streak%'
)
SELECT
  trigger_task,
  COUNT(*) AS rows,
  COUNT(DISTINCT topic) AS distinct_topics,
  SUM(CASE WHEN COALESCE(references_urls, '') = '' THEN 1 ELSE 0 END) AS blank_refs,
  MIN(ts) AS first_ts,
  MAX(ts) AS last_ts
FROM repeat_research
GROUP BY trigger_task
HAVING rows >= 3
ORDER BY rows DESC
LIMIT 20;

WITH ordered AS (
  SELECT
    id,
    topic,
    trigger_task,
    LAG(topic) OVER (ORDER BY id) AS prev_topic,
    LAG(trigger_task) OVER (ORDER BY id) AS prev_trigger
  FROM research
)
SELECT
  COUNT(*) AS adjacent_same_trigger,
  SUM(CASE WHEN topic = prev_topic THEN 1 ELSE 0 END) AS adjacent_same_topic,
  SUM(CASE WHEN lower(replace(topic, ' ', '-')) = lower(replace(prev_topic, ' ', '-')) THEN 1 ELSE 0 END) AS adjacent_same_space_norm
FROM ordered
WHERE trigger_task = prev_trigger;
