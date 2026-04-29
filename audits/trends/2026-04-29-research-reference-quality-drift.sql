-- Historical research-reference quality drift audit for temple-central.db.
-- Read-only query pack used by:
-- audits/trends/2026-04-29-research-reference-quality-drift.md

.headers on
.mode column

SELECT
  count(*) AS research_rows,
  sum(CASE WHEN references_urls IS NULL OR trim(references_urls) = '' THEN 1 ELSE 0 END) AS missing_refs,
  sum(CASE WHEN trigger_task IS NULL OR trim(trigger_task) = '' THEN 1 ELSE 0 END) AS missing_trigger,
  sum(CASE WHEN findings IS NULL OR trim(findings) = '' THEN 1 ELSE 0 END) AS missing_findings,
  min(ts) AS first_ts,
  max(ts) AS last_ts
FROM research;

SELECT
  substr(ts, 1, 10) AS day,
  count(*) AS rows,
  count(DISTINCT topic) AS topics,
  sum(CASE WHEN references_urls IS NULL OR trim(references_urls) = '' THEN 1 ELSE 0 END) AS missing_refs,
  sum(CASE WHEN trigger_task IS NULL OR trim(trigger_task) = '' THEN 1 ELSE 0 END) AS missing_trigger
FROM research
GROUP BY day
ORDER BY day;

WITH refs AS (
  SELECT
    id,
    topic,
    references_urls,
    CASE WHEN references_urls LIKE '%http://%' OR references_urls LIKE '%https://%' THEN 1 ELSE 0 END AS has_url,
    CASE WHEN references_urls LIKE '%/Users/%' THEN 1 ELSE 0 END AS has_local,
    CASE WHEN references_urls IS NULL OR trim(references_urls) = '' THEN 1 ELSE 0 END AS missing
  FROM research
)
SELECT
  count(*) AS rows,
  sum(missing) AS missing_refs,
  sum(has_url) AS has_url_refs,
  sum(has_local) AS has_local_refs,
  sum(CASE WHEN missing = 0 AND has_url = 0 AND has_local = 0 THEN 1 ELSE 0 END) AS opaque_refs
FROM refs;

WITH r AS (
  SELECT
    id,
    ts,
    topic,
    trigger_task,
    lower(coalesce(findings, '')) AS findings,
    coalesce(references_urls, '') AS refs
  FROM research
)
SELECT
  count(*) AS rows,
  sum(CASE WHEN findings GLOB '*recommend*' THEN 1 ELSE 0 END) AS recommend_rows,
  sum(CASE WHEN findings GLOB '*added*' OR findings GLOB '*created*' THEN 1 ELSE 0 END) AS artifact_claim_rows,
  sum(CASE WHEN refs LIKE '%/Users/%' THEN 1 ELSE 0 END) AS local_artifact_ref_rows,
  sum(
    CASE
      WHEN (findings GLOB '*added*' OR findings GLOB '*created*')
        AND refs NOT LIKE '%/Users/%'
      THEN 1 ELSE 0
    END
  ) AS artifact_claim_no_local_ref
FROM r;

WITH r AS (
  SELECT
    *,
    lower(replace(replace(replace(topic, '-', ' '), '_', ' '), '  ', ' ')) AS norm_topic
  FROM research
)
SELECT
  norm_topic,
  count(*) AS rows,
  count(DISTINCT topic) AS variants,
  count(DISTINCT trigger_task) AS triggers,
  sum(CASE WHEN references_urls IS NULL OR trim(references_urls) = '' THEN 1 ELSE 0 END) AS missing_refs,
  min(ts) AS first_ts,
  max(ts) AS last_ts
FROM r
GROUP BY norm_topic
HAVING rows >= 4 OR variants >= 2
ORDER BY rows DESC, variants DESC
LIMIT 60;

SELECT
  topic,
  count(*) AS rows,
  count(DISTINCT trigger_task) AS triggers,
  sum(CASE WHEN references_urls IS NULL OR trim(references_urls) = '' THEN 1 ELSE 0 END) AS missing_refs,
  min(ts) AS first_ts,
  max(ts) AS last_ts
FROM research
GROUP BY topic
HAVING rows >= 4
ORDER BY rows DESC, topic
LIMIT 80;

SELECT
  id,
  ts,
  topic,
  trigger_task,
  substr(replace(replace(findings, char(10), ' '), char(13), ' '), 1, 130) AS sample
FROM research
WHERE references_urls IS NULL OR trim(references_urls) = ''
ORDER BY ts
LIMIT 30;
