-- Historical drift audit: repeat-task research saturation versus Law 7 escalation evidence.
-- Source DB: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Read-only usage:
--   sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-02-repeat-task-research-saturation-drift.sql

.print '== repeat/stuck-task research share =='
WITH tagged AS (
  SELECT
    *,
    lower(topic) AS topic_lc
  FROM research
),
classified AS (
  SELECT
    *,
    CASE
      WHEN topic_lc LIKE '%repeat%task%'
        OR topic_lc LIKE '%same%task%'
        OR topic_lc LIKE '%stuck%'
        OR topic_lc LIKE '%streak%'
      THEN 1 ELSE 0
    END AS repeat_topic
  FROM tagged
)
SELECT
  count(*) AS total_research,
  sum(repeat_topic) AS repeat_topic_rows,
  round(100.0 * sum(repeat_topic) / count(*), 1) AS repeat_topic_pct,
  min(CASE WHEN repeat_topic = 1 THEN ts END) AS first_repeat_topic_ts,
  max(CASE WHEN repeat_topic = 1 THEN ts END) AS last_repeat_topic_ts
FROM classified;

.print ''
.print '== repeat/stuck-task rows by day =='
WITH tagged AS (
  SELECT
    *,
    lower(topic) AS topic_lc
  FROM research
),
classified AS (
  SELECT
    *,
    CASE
      WHEN topic_lc LIKE '%repeat%task%'
        OR topic_lc LIKE '%same%task%'
        OR topic_lc LIKE '%stuck%'
        OR topic_lc LIKE '%streak%'
      THEN 1 ELSE 0
    END AS repeat_topic
  FROM tagged
)
SELECT
  date(ts) AS day,
  count(*) AS total_rows,
  sum(repeat_topic) AS repeat_topic_rows,
  sum(repeat_topic AND (references_urls IS NULL OR trim(references_urls) = '')) AS missing_refs,
  count(DISTINCT trigger_task) AS distinct_triggers
FROM classified
GROUP BY date(ts)
ORDER BY day;

.print ''
.print '== repeated triggers inside repeat/stuck-task research =='
WITH r AS (
  SELECT
    *,
    lower(topic) AS topic_lc
  FROM research
  WHERE lower(topic) LIKE '%repeat%task%'
    OR lower(topic) LIKE '%same%task%'
    OR lower(topic) LIKE '%stuck%'
    OR lower(topic) LIKE '%streak%'
)
SELECT
  trigger_task,
  count(*) AS rows,
  count(DISTINCT topic) AS distinct_topics,
  min(ts) AS first_ts,
  max(ts) AS last_ts,
  sum(references_urls IS NULL OR trim(references_urls) = '') AS missing_refs
FROM r
GROUP BY trigger_task
HAVING count(*) >= 3
ORDER BY rows DESC, trigger_task
LIMIT 30;

.print ''
.print '== topic cardinality and provenance for repeat/stuck-task research =='
WITH r AS (
  SELECT
    *,
    lower(topic) AS topic_lc
  FROM research
  WHERE lower(topic) LIKE '%repeat%task%'
    OR lower(topic) LIKE '%same%task%'
    OR lower(topic) LIKE '%stuck%'
    OR lower(topic) LIKE '%streak%'
)
SELECT
  count(*) AS rows,
  count(DISTINCT topic) AS distinct_topics,
  round(1.0 * count(DISTINCT topic) / count(*), 2) AS topic_per_row_ratio,
  sum(references_urls IS NULL OR trim(references_urls) = '') AS missing_refs,
  count(DISTINCT trigger_task) AS distinct_triggers
FROM r;

.print ''
.print '== adjacent repeat/stuck-task research cadence =='
WITH r AS (
  SELECT
    *,
    lower(topic) AS topic_lc
  FROM research
  WHERE lower(topic) LIKE '%repeat%task%'
    OR lower(topic) LIKE '%same%task%'
    OR lower(topic) LIKE '%stuck%'
    OR lower(topic) LIKE '%streak%'
),
ordered AS (
  SELECT
    *,
    lag(ts) OVER (ORDER BY ts, id) AS prev_ts
  FROM r
)
SELECT
  count(*) AS adjacent_rows,
  sum(strftime('%s', ts) - strftime('%s', prev_ts) <= 120) AS within_2m,
  sum(strftime('%s', ts) - strftime('%s', prev_ts) <= 600) AS within_10m,
  min(ts) AS first_ts,
  max(ts) AS last_ts
FROM ordered
WHERE prev_ts IS NOT NULL;

.print ''
.print '== busiest repeat/stuck-task research hours =='
WITH r AS (
  SELECT
    *,
    lower(topic) AS topic_lc
  FROM research
  WHERE lower(topic) LIKE '%repeat%task%'
    OR lower(topic) LIKE '%same%task%'
    OR lower(topic) LIKE '%stuck%'
    OR lower(topic) LIKE '%streak%'
),
by_hour AS (
  SELECT
    strftime('%Y-%m-%dT%H:00:00', ts) AS hour,
    count(*) AS rows,
    count(DISTINCT trigger_task) AS triggers,
    sum(references_urls IS NULL OR trim(references_urls) = '') AS missing_refs
  FROM r
  GROUP BY hour
)
SELECT *
FROM by_hour
ORDER BY rows DESC, hour
LIMIT 20;

.print ''
.print '== Law 7 threshold mentions versus violation sink =='
WITH r AS (
  SELECT
    *,
    lower(topic || ' ' || coalesce(findings, '')) AS hay
  FROM research
  WHERE lower(topic) LIKE '%repeat%task%'
    OR lower(topic) LIKE '%same%task%'
    OR lower(topic) LIKE '%stuck%'
    OR lower(topic) LIKE '%streak%'
)
SELECT
  count(*) AS repeat_research_rows,
  sum(hay LIKE '%>=3%'
    OR hay LIKE '%3x%'
    OR hay LIKE '%streak=3%'
    OR hay LIKE '%streak reached 3%'
    OR hay LIKE '%consecutive%3%'
    OR hay LIKE '%repeated 3%') AS threshold_mentions,
  (SELECT count(*) FROM violations) AS violation_rows
FROM r;
