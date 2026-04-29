-- Historical validation-outcome semantics drift audit for temple-central.db.
-- Read-only query pack used by:
-- audits/trends/2026-04-29-validation-outcome-semantics-drift.md

.headers on
.mode column

SELECT
  agent,
  status,
  count(*) AS rows,
  sum(validation_cmd IS NOT NULL AND trim(validation_cmd) <> '') AS has_validation_cmd,
  sum(validation_result IS NOT NULL AND trim(validation_result) <> '') AS has_validation_result,
  sum(error_msg IS NOT NULL AND trim(error_msg) <> '') AS has_error_msg,
  sum(coalesce(lines_added, 0) + coalesce(lines_removed, 0)) AS churn
FROM iterations
GROUP BY agent, status
ORDER BY agent, status;

SELECT
  agent,
  count(*) AS rows,
  sum(status = 'pass'
      AND (validation_cmd IS NULL OR trim(validation_cmd) = '')) AS pass_without_cmd,
  sum(status = 'pass'
      AND (validation_result IS NULL OR trim(validation_result) = '')) AS pass_without_result,
  sum(status IN ('fail', 'blocked')
      AND (error_msg IS NULL OR trim(error_msg) = '')) AS fail_blocked_without_error_msg,
  sum(status = 'pass'
      AND (
        lower(coalesce(validation_result, '')) GLOB '*skipped*'
        OR lower(coalesce(validation_result, '')) GLOB '*unavailable*'
        OR lower(coalesce(validation_result, '')) GLOB '*download skipped*'
        OR lower(coalesce(validation_result, '')) GLOB '*harness skipped*'
      )) AS pass_result_skip_unavailable,
  sum(status = 'pass'
      AND (
        lower(coalesce(validation_result, '')) GLOB '*fail*'
        OR lower(coalesce(validation_result, '')) GLOB '*error*'
      )) AS pass_result_failure_words
FROM iterations
GROUP BY agent
ORDER BY agent;

SELECT
  agent,
  status,
  count(*) AS rows,
  min(id) AS first_id,
  max(id) AS last_id
FROM iterations
WHERE (
  lower(coalesce(validation_result, '')) GLOB '*skipped*'
  OR lower(coalesce(validation_result, '')) GLOB '*unavailable*'
  OR lower(coalesce(validation_result, '')) GLOB '*download skipped*'
  OR lower(coalesce(validation_result, '')) GLOB '*harness skipped*'
)
GROUP BY agent, status
ORDER BY rows DESC;

SELECT
  CASE
    WHEN lower(coalesce(validation_result, '')) GLOB '*remote*'
      OR lower(coalesce(validation_cmd, '')) GLOB '*ssh *'
      THEN 'remote_or_ssh_backstop'
    WHEN lower(coalesce(validation_result, '')) GLOB '*qemu*'
      THEN 'local_qemu_skip'
    WHEN lower(coalesce(validation_result, '')) GLOB '*iso*'
      THEN 'iso_unavailable'
    ELSE 'other_skip_unavailable'
  END AS evidence_shape,
  count(*) AS rows,
  min(id) AS first_id,
  max(id) AS last_id
FROM iterations
WHERE agent = 'modernization'
  AND status = 'pass'
  AND (
    lower(coalesce(validation_result, '')) GLOB '*skipped*'
    OR lower(coalesce(validation_result, '')) GLOB '*unavailable*'
    OR lower(coalesce(validation_result, '')) GLOB '*download skipped*'
    OR lower(coalesce(validation_result, '')) GLOB '*harness skipped*'
  )
GROUP BY evidence_shape
ORDER BY rows DESC;

SELECT
  id,
  ts,
  agent,
  task_id,
  status,
  substr(replace(coalesce(validation_cmd, ''), char(10), ' '), 1, 140) AS validation_cmd_sample,
  substr(replace(coalesce(validation_result, ''), char(10), ' '), 1, 120) AS validation_result_sample,
  substr(replace(coalesce(notes, ''), char(10), ' '), 1, 120) AS notes_sample
FROM iterations
WHERE status = 'pass'
  AND (
    lower(coalesce(validation_result, '')) GLOB '*fail*'
    OR lower(coalesce(validation_result, '')) GLOB '*error*'
  )
ORDER BY id;

SELECT
  task_id,
  status,
  count(*) AS rows,
  min(id) AS first_id,
  max(id) AS last_id
FROM iterations
WHERE agent = 'sanhedrin'
  AND status IN ('fail', 'blocked')
  AND (error_msg IS NULL OR trim(error_msg) = '')
GROUP BY task_id, status
ORDER BY rows DESC, task_id;

SELECT
  id,
  ts,
  task_id,
  status,
  substr(replace(coalesce(notes, ''), char(10), ' '), 1, 160) AS notes_sample
FROM iterations
WHERE agent = 'sanhedrin'
  AND status IN ('fail', 'blocked')
  AND (error_msg IS NULL OR trim(error_msg) = '')
ORDER BY id
LIMIT 20;

WITH builder_rows AS (
  SELECT
    substr(ts, 1, 10) AS day,
    agent,
    status,
    lower(coalesce(validation_result, '')) AS result_text
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
    AND ts GLOB '????-??-??T??:??:??*'
)
SELECT
  day,
  agent,
  count(*) AS rows,
  sum(status = 'pass') AS pass_rows,
  sum(status = 'pass'
      AND (
        result_text GLOB '*skipped*'
        OR result_text GLOB '*unavailable*'
        OR result_text GLOB '*harness skipped*'
      )) AS pass_skip_unavailable_rows
FROM builder_rows
GROUP BY day, agent
HAVING pass_skip_unavailable_rows > 0
ORDER BY day, agent;
