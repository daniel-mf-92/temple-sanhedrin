-- Historical trend audit: validation command redaction / truncation drift.
-- Read-only target:
--   /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db

.headers on
.mode column

WITH builder AS (
  SELECT *
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
)
SELECT
  agent,
  COUNT(*) AS total_rows,
  SUM(INSTR(validation_cmd, '...') > 0) AS redacted_cmd_rows,
  SUM(INSTR(validation_cmd, '...') > 0 AND validation_cmd LIKE '%qemu%') AS redacted_qemu_rows,
  SUM(INSTR(validation_cmd, '...') > 0 AND validation_cmd LIKE '%ssh%') AS redacted_ssh_rows,
  SUM(INSTR(validation_cmd, '...') > 0 AND validation_cmd LIKE '%python3 - <<%') AS redacted_heredoc_rows,
  SUM(LENGTH(validation_cmd) >= 250) AS cmd_rows_ge_250_chars,
  MAX(LENGTH(validation_cmd)) AS max_cmd_len
FROM builder
GROUP BY agent
ORDER BY agent;

WITH builder AS (
  SELECT *
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
),
redacted AS (
  SELECT *, SUBSTR(ts, 1, 10) AS day
  FROM builder
  WHERE INSTR(validation_cmd, '...') > 0
)
SELECT
  day,
  agent,
  COUNT(*) AS rows,
  SUM(validation_cmd LIKE '%qemu%') AS qemu_rows,
  SUM(validation_cmd LIKE '%ssh%') AS ssh_rows,
  SUM(validation_cmd LIKE '%python3 - <<%') AS heredoc_rows
FROM redacted
GROUP BY day, agent
ORDER BY day, agent;

SELECT
  agent,
  task_id,
  ts,
  LENGTH(validation_cmd) AS cmd_len,
  validation_cmd
FROM iterations
WHERE agent IN ('modernization', 'inference')
  AND INSTR(validation_cmd, '...') > 0
ORDER BY ts DESC, agent, task_id;

SELECT
  agent,
  COUNT(*) AS rows,
  MIN(ts) AS first_ts,
  MAX(ts) AS last_ts,
  SUM(CASE WHEN status != 'pass' THEN 1 ELSE 0 END) AS non_pass_rows
FROM iterations
WHERE agent IN ('modernization', 'inference')
GROUP BY agent
ORDER BY agent;
