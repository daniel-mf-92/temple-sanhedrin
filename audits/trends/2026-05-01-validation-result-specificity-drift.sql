-- Historical drift audit: validation_result specificity in temple-central.db.
-- Read-only usage:
-- sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-01-validation-result-specificity-drift.sql

.print '== builder validation result specificity summary =='
WITH builder AS (
  SELECT
    agent,
    validation_cmd,
    validation_result,
    files_changed,
    CASE
      WHEN agent = 'inference' AND lower(validation_result) = 'ok' THEN 1
      WHEN agent = 'modernization' AND validation_result = 'exit 0' THEN 1
      ELSE 0
    END AS exact_generic,
    CASE
      WHEN validation_result GLOB '*[0-9]*' THEN 1
      ELSE 0
    END AS result_has_digit,
    CASE
      WHEN validation_result LIKE '%=%' THEN 1
      ELSE 0
    END AS result_has_named_check,
    CASE
      WHEN validation_result LIKE '%passed%' THEN 1
      ELSE 0
    END AS result_has_passed,
    CASE
      WHEN validation_result LIKE '%skipped%'
        OR validation_result LIKE '%skip%'
        OR validation_result LIKE '%unavailable%'
      THEN 1
      ELSE 0
    END AS result_has_skip_or_unavailable,
    CASE
      WHEN validation_cmd LIKE '%qemu%'
        OR validation_cmd LIKE '%QEMU%'
        OR validation_result LIKE '%qemu%'
        OR validation_result LIKE '%QEMU%'
      THEN 1
      ELSE 0
    END AS has_qemu_evidence,
    CASE
      WHEN files_changed LIKE '%,%' THEN 1
      ELSE 0
    END AS multi_file_row
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
)
SELECT
  agent,
  count(*) AS rows,
  sum(exact_generic) AS exact_generic_rows,
  round(100.0 * sum(exact_generic) / count(*), 1) AS exact_generic_pct,
  sum(result_has_digit) AS result_has_digit_rows,
  sum(result_has_named_check) AS result_has_named_check_rows,
  sum(result_has_passed) AS result_has_passed_rows,
  sum(result_has_skip_or_unavailable) AS skip_or_unavailable_rows,
  sum(has_qemu_evidence) AS qemu_evidence_rows,
  sum(has_qemu_evidence AND result_has_skip_or_unavailable) AS qemu_skip_unavailable_rows,
  sum(multi_file_row) AS multi_file_rows,
  sum(exact_generic AND multi_file_row) AS generic_multi_file_rows
FROM builder
GROUP BY agent
ORDER BY agent;

.print ''
.print '== combined generic result share =='
WITH builder AS (
  SELECT
    CASE
      WHEN agent = 'inference' AND lower(validation_result) = 'ok' THEN 1
      WHEN agent = 'modernization' AND validation_result = 'exit 0' THEN 1
      ELSE 0
    END AS exact_generic
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
)
SELECT
  count(*) AS rows,
  sum(exact_generic) AS exact_generic_rows,
  round(100.0 * sum(exact_generic) / count(*), 1) AS exact_generic_pct
FROM builder;

.print ''
.print '== distinct command/result compression =='
SELECT
  agent,
  count(DISTINCT validation_cmd) AS unique_validation_cmds,
  count(DISTINCT validation_result) AS unique_validation_results,
  round(1.0 * count(DISTINCT validation_result) / count(DISTINCT validation_cmd), 2) AS result_per_cmd_ratio
FROM iterations
WHERE agent IN ('modernization', 'inference')
GROUP BY agent
ORDER BY agent;

.print ''
.print '== daily generic result coverage =='
WITH daily AS (
  SELECT
    agent,
    date(ts) AS day,
    count(*) AS rows,
    sum(
      (agent = 'inference' AND lower(validation_result) = 'ok')
      OR (agent = 'modernization' AND validation_result = 'exit 0')
    ) AS generic_rows
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
  GROUP BY agent, date(ts)
)
SELECT
  agent,
  day,
  rows,
  generic_rows,
  round(100.0 * generic_rows / rows, 1) AS generic_pct
FROM daily
ORDER BY day, agent;

.print ''
.print '== days at or above 90 percent generic results =='
WITH daily AS (
  SELECT
    agent,
    date(ts) AS day,
    count(*) AS rows,
    sum(
      (agent = 'inference' AND lower(validation_result) = 'ok')
      OR (agent = 'modernization' AND validation_result = 'exit 0')
    ) AS generic_rows
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
  GROUP BY agent, date(ts)
)
SELECT
  agent,
  day,
  rows,
  generic_rows,
  round(100.0 * generic_rows / rows, 1) AS generic_pct
FROM daily
WHERE round(100.0 * generic_rows / rows, 1) >= 90.0
ORDER BY generic_pct DESC, rows DESC;

.print ''
.print '== top repeated validation results =='
SELECT
  agent,
  validation_result,
  count(*) AS rows
FROM iterations
WHERE agent IN ('modernization', 'inference')
GROUP BY agent, validation_result
ORDER BY agent, rows DESC
LIMIT 20;

.print ''
.print '== repeated commands with generic ok/exit evidence =='
SELECT
  agent,
  validation_cmd,
  count(*) AS rows,
  sum(
    (agent = 'inference' AND lower(validation_result) = 'ok')
    OR (agent = 'modernization' AND validation_result = 'exit 0')
  ) AS generic_rows
FROM iterations
WHERE agent IN ('modernization', 'inference')
GROUP BY agent, validation_cmd
HAVING rows >= 20
ORDER BY generic_rows DESC, rows DESC;
