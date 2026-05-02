-- Historical drift audit: host-absolute validation path provenance.
-- Source DB: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
--
-- Usage:
-- sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-02-absolute-validation-path-provenance-drift.sql

.headers on
.mode column

WITH builder_rows AS (
  SELECT
    *,
    LOWER(
      COALESCE(validation_cmd, '') || ' ' ||
      COALESCE(validation_result, '') || ' ' ||
      COALESCE(notes, '') || ' ' ||
      COALESCE(files_changed, '')
    ) AS evidence_text
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
)
SELECT
  agent,
  COUNT(*) AS rows,
  SUM(evidence_text LIKE '%/tmp/%' OR
      evidence_text LIKE '%/users/%' OR
      evidence_text LIKE '%/home/azureuser/%') AS abs_path_rows,
  ROUND(
    100.0 * SUM(evidence_text LIKE '%/tmp/%' OR
                evidence_text LIKE '%/users/%' OR
                evidence_text LIKE '%/home/azureuser/%') / COUNT(*),
    2
  ) AS abs_path_pct,
  SUM(evidence_text LIKE '%/tmp/%') AS tmp_rows,
  SUM(evidence_text LIKE '%/users/%') AS users_rows,
  SUM(evidence_text LIKE '%/home/azureuser/%') AS azure_home_rows,
  SUM(evidence_text LIKE '%/tmp/%' AND evidence_text LIKE '%book%truth%') AS tmp_booktruth_rows,
  SUM(evidence_text LIKE '%/tmp/%' AND
      (evidence_text LIKE '%mktemp%' OR evidence_text LIKE '%tmpdir%')) AS tmp_mktemp_rows,
  SUM(evidence_text LIKE '%/tmp/%' AND
      evidence_text NOT LIKE '%mktemp%' AND
      evidence_text NOT LIKE '%tmpdir%') AS tmp_without_explicit_mktemp_rows
FROM builder_rows
GROUP BY agent
ORDER BY agent;

WITH builder_rows AS (
  SELECT
    *,
    LOWER(
      COALESCE(validation_cmd, '') || ' ' ||
      COALESCE(validation_result, '') || ' ' ||
      COALESCE(notes, '') || ' ' ||
      COALESCE(files_changed, '')
    ) AS evidence_text
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
)
SELECT
  agent,
  SUM(evidence_text LIKE '%replay%') AS replay_rows,
  SUM((evidence_text LIKE '%/tmp/%' OR
       evidence_text LIKE '%/users/%' OR
       evidence_text LIKE '%/home/azureuser/%') AND
      evidence_text LIKE '%replay%') AS replay_abs_rows,
  SUM(evidence_text LIKE '%fixture%') AS fixture_rows,
  SUM((evidence_text LIKE '%/tmp/%' OR
       evidence_text LIKE '%/users/%' OR
       evidence_text LIKE '%/home/azureuser/%') AND
      evidence_text LIKE '%fixture%') AS fixture_abs_rows,
  SUM(evidence_text LIKE '%digest%') AS digest_rows,
  SUM((evidence_text LIKE '%/tmp/%' OR
       evidence_text LIKE '%/users/%' OR
       evidence_text LIKE '%/home/azureuser/%') AND
      evidence_text LIKE '%digest%') AS digest_abs_rows
FROM builder_rows
GROUP BY agent
ORDER BY agent;

WITH builder_rows AS (
  SELECT
    *,
    SUBSTR(ts, 1, 10) AS day,
    LOWER(
      COALESCE(validation_cmd, '') || ' ' ||
      COALESCE(validation_result, '') || ' ' ||
      COALESCE(notes, '') || ' ' ||
      COALESCE(files_changed, '')
    ) AS evidence_text
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
)
SELECT
  day,
  agent,
  COUNT(*) AS rows,
  SUM(evidence_text LIKE '%/tmp/%' OR
      evidence_text LIKE '%/users/%' OR
      evidence_text LIKE '%/home/azureuser/%') AS abs_path_rows,
  SUM(evidence_text LIKE '%/tmp/%' AND evidence_text LIKE '%book%truth%') AS tmp_booktruth_rows
FROM builder_rows
GROUP BY day, agent
HAVING abs_path_rows > 0
ORDER BY day, agent;

WITH builder_rows AS (
  SELECT
    *,
    LOWER(
      COALESCE(validation_cmd, '') || ' ' ||
      COALESCE(validation_result, '') || ' ' ||
      COALESCE(notes, '') || ' ' ||
      COALESCE(files_changed, '')
    ) AS evidence_text
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
),
classified AS (
  SELECT
    CASE
      WHEN evidence_text LIKE '%/tmp/%' THEN 'tmp'
      WHEN evidence_text LIKE '%/home/azureuser/%' THEN 'azure_home'
      WHEN evidence_text LIKE '%/users/%' THEN 'users'
      ELSE 'none'
    END AS path_class,
    *
  FROM builder_rows
  WHERE evidence_text LIKE '%/tmp/%'
     OR evidence_text LIKE '%/users/%'
     OR evidence_text LIKE '%/home/azureuser/%'
)
SELECT
  path_class,
  agent,
  COUNT(*) AS rows,
  MIN(ts) AS first_ts,
  MAX(ts) AS last_ts
FROM classified
GROUP BY path_class, agent
ORDER BY path_class, agent;

WITH builder_rows AS (
  SELECT
    id,
    ts,
    agent,
    task_id,
    validation_cmd,
    notes,
    LOWER(
      COALESCE(validation_cmd, '') || ' ' ||
      COALESCE(validation_result, '') || ' ' ||
      COALESCE(notes, '') || ' ' ||
      COALESCE(files_changed, '')
    ) AS evidence_text
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
)
SELECT
  id,
  ts,
  agent,
  task_id,
  CASE
    WHEN evidence_text LIKE '%/tmp/%' THEN 'tmp'
    WHEN evidence_text LIKE '%/home/azureuser/%' THEN 'azure_home'
    WHEN evidence_text LIKE '%/users/%' THEN 'users'
    ELSE 'other'
  END AS path_class,
  SUBSTR(validation_cmd, 1, 180) AS cmd_excerpt,
  SUBSTR(notes, 1, 100) AS notes_excerpt
FROM builder_rows
WHERE evidence_text LIKE '%/tmp/%'
   OR evidence_text LIKE '%/users/%'
   OR evidence_text LIKE '%/home/azureuser/%'
ORDER BY id DESC
LIMIT 20;
