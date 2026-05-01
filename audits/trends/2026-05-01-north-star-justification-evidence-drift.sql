-- Historical north-star justification evidence drift audit.
-- Source DB: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Run with:
--   sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-01-north-star-justification-evidence-drift.sql

.headers on
.mode column

WITH builder_rows AS (
  SELECT
    id,
    ts,
    agent,
    task_id,
    status,
    files_changed,
    validation_cmd,
    validation_result,
    notes,
    lower(
      coalesce(notes, '') || ' ' ||
      coalesce(validation_cmd, '') || ' ' ||
      coalesce(validation_result, '') || ' ' ||
      coalesce(files_changed, '')
    ) AS evidence_text
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
),
scored AS (
  SELECT
    *,
    CASE
      WHEN evidence_text GLOB '*north*star*'
        OR evidence_text LIKE '%north_star%'
      THEN 1 ELSE 0
    END AS mentions_north_star,
    CASE
      WHEN lower(coalesce(validation_cmd, '')) LIKE '%north-star-e2e%'
        OR lower(coalesce(validation_cmd, '')) LIKE '%north_star_e2e%'
      THEN 1 ELSE 0
    END AS runs_north_star_e2e,
    CASE WHEN lower(coalesce(notes, '')) LIKE '%queue%' THEN 1 ELSE 0 END AS mentions_queue,
    CASE
      WHEN lower(coalesce(notes, '')) LIKE '%book%'
        OR lower(coalesce(notes, '')) LIKE '%secure%'
        OR lower(coalesce(notes, '')) LIKE '%gpu%'
        OR lower(coalesce(notes, '')) LIKE '%integer%'
        OR lower(coalesce(notes, '')) LIKE '%token%'
      THEN 1 ELSE 0
    END AS mentions_domain
  FROM builder_rows
)
SELECT
  'overall_north_star_evidence' AS section,
  agent,
  count(*) AS rows,
  sum(mentions_north_star) AS north_star_mentions,
  sum(runs_north_star_e2e) AS north_star_e2e_cmd_rows,
  sum(mentions_queue) AS queue_note_rows,
  sum(mentions_domain) AS domain_note_rows,
  sum(CASE WHEN notes IS NULL OR trim(notes) = '' THEN 1 ELSE 0 END) AS blank_note_rows
FROM scored
GROUP BY agent
ORDER BY agent;

WITH builder_rows AS (
  SELECT
    ts,
    agent,
    lower(
      coalesce(notes, '') || ' ' ||
      coalesce(validation_cmd, '') || ' ' ||
      coalesce(validation_result, '') || ' ' ||
      coalesce(files_changed, '')
    ) AS evidence_text,
    lower(coalesce(validation_cmd, '')) AS cmd
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
),
scored AS (
  SELECT
    agent,
    substr(ts, 1, 10) AS day,
    CASE
      WHEN evidence_text GLOB '*north*star*'
        OR evidence_text LIKE '%north_star%'
      THEN 1 ELSE 0
    END AS mentions_north_star,
    CASE
      WHEN cmd LIKE '%north-star-e2e%'
        OR cmd LIKE '%north_star_e2e%'
      THEN 1 ELSE 0
    END AS runs_north_star_e2e
  FROM builder_rows
)
SELECT
  'daily_north_star_evidence' AS section,
  agent,
  day,
  count(*) AS rows,
  sum(mentions_north_star) AS north_star_mentions,
  sum(runs_north_star_e2e) AS north_star_e2e_cmd_rows
FROM scored
GROUP BY agent, day
ORDER BY day, agent;

WITH scored AS (
  SELECT
    agent,
    status,
    CASE
      WHEN lower(
        coalesce(notes, '') || ' ' ||
        coalesce(validation_cmd, '') || ' ' ||
        coalesce(validation_result, '') || ' ' ||
        coalesce(files_changed, '')
      ) GLOB '*north*star*'
        OR lower(
          coalesce(notes, '') || ' ' ||
          coalesce(validation_cmd, '') || ' ' ||
          coalesce(validation_result, '') || ' ' ||
          coalesce(files_changed, '')
        ) LIKE '%north_star%'
      THEN 1 ELSE 0
    END AS mentions_north_star
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
)
SELECT
  'status_north_star_evidence' AS section,
  agent,
  status,
  count(*) AS rows,
  sum(mentions_north_star) AS north_star_mentions
FROM scored
GROUP BY agent, status
ORDER BY agent, status;

SELECT
  'latest_builder_notes_without_north_star' AS section,
  agent,
  task_id,
  ts,
  substr(notes, 1, 180) AS notes,
  substr(validation_cmd, 1, 160) AS validation_cmd
FROM iterations
WHERE agent IN ('modernization', 'inference')
  AND lower(
    coalesce(notes, '') || ' ' ||
    coalesce(validation_cmd, '') || ' ' ||
    coalesce(validation_result, '') || ' ' ||
    coalesce(files_changed, '')
  ) NOT GLOB '*north*star*'
  AND lower(
    coalesce(notes, '') || ' ' ||
    coalesce(validation_cmd, '') || ' ' ||
    coalesce(validation_result, '') || ' ' ||
    coalesce(files_changed, '')
  ) NOT LIKE '%north_star%'
ORDER BY id DESC
LIMIT 20;
