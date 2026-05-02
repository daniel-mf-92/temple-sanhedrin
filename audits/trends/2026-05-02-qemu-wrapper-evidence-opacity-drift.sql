-- Historical drift audit: QEMU wrapper evidence opacity in temple-central.db.
-- Source DB: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Usage:
--   sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-02-qemu-wrapper-evidence-opacity-drift.sql

.print '== Iteration coverage by agent =='
SELECT
  agent,
  COUNT(*) AS rows,
  MIN(CASE WHEN ts LIKE '____-__-__T__:__:__%' THEN ts END) AS first_iso_ts,
  MAX(CASE WHEN ts LIKE '____-__-__T__:__:__%' THEN ts END) AS last_iso_ts
FROM iterations
GROUP BY agent
ORDER BY agent;

.print ''
.print '== QEMU validation command shape =='
WITH q AS (
  SELECT *
  FROM iterations
  WHERE agent = 'modernization'
    AND LOWER(
      COALESCE(validation_cmd, '') || ' ' ||
      COALESCE(validation_result, '') || ' ' ||
      COALESCE(notes, '')
    ) LIKE '%qemu%'
)
SELECT
  COUNT(*) AS qemu_rows,
  SUM(LOWER(COALESCE(validation_cmd, '')) LIKE '%qemu-system%') AS direct_qemu_system_cmds,
  SUM(LOWER(COALESCE(validation_cmd, '')) LIKE '%qemu-%') AS qemu_wrapper_cmds,
  SUM(
    LOWER(COALESCE(validation_cmd, '')) LIKE '%-nic none%'
    OR LOWER(COALESCE(validation_cmd, '')) LIKE '%-net none%'
  ) AS cmd_airgap_tokens,
  SUM(LOWER(COALESCE(validation_cmd, '')) LIKE '%readonly=on%') AS cmd_readonly_tokens,
  SUM(
    LOWER(COALESCE(validation_result, '')) LIKE '%-nic none%'
    OR LOWER(COALESCE(validation_result, '')) LIKE '%-net none%'
  ) AS result_airgap_tokens,
  SUM(LOWER(COALESCE(validation_result, '')) LIKE '%readonly=on%') AS result_readonly_tokens
FROM q;

.print ''
.print '== Modernization QEMU share =='
SELECT
  COUNT(*) AS total_modernization_rows,
  SUM(
    LOWER(
      COALESCE(validation_cmd, '') || ' ' ||
      COALESCE(validation_result, '') || ' ' ||
      COALESCE(notes, '')
    ) LIKE '%qemu%'
  ) AS qemu_rows,
  ROUND(
    100.0 * SUM(
      LOWER(
        COALESCE(validation_cmd, '') || ' ' ||
        COALESCE(validation_result, '') || ' ' ||
        COALESCE(notes, '')
      ) LIKE '%qemu%'
    ) / COUNT(*),
    1
  ) AS qemu_pct
FROM iterations
WHERE agent = 'modernization';

.print ''
.print '== QEMU rows by day =='
SELECT
  DATE(ts) AS day,
  COUNT(*) AS qemu_rows
FROM iterations
WHERE agent = 'modernization'
  AND ts LIKE '____-__-__T__:__:__%'
  AND LOWER(
    COALESCE(validation_cmd, '') || ' ' ||
    COALESCE(validation_result, '') || ' ' ||
    COALESCE(notes, '')
  ) LIKE '%qemu%'
GROUP BY DATE(ts)
ORDER BY day;

.print ''
.print '== QEMU validation result terseness =='
WITH q AS (
  SELECT *
  FROM iterations
  WHERE agent = 'modernization'
    AND LOWER(
      COALESCE(validation_cmd, '') || ' ' ||
      COALESCE(validation_result, '') || ' ' ||
      COALESCE(notes, '')
    ) LIKE '%qemu%'
)
SELECT
  COUNT(*) AS qemu_rows,
  SUM(validation_result = 'exit 0') AS exit0_rows,
  SUM(LENGTH(COALESCE(validation_result, '')) <= 6) AS terse_rows,
  ROUND(AVG(LENGTH(COALESCE(validation_result, ''))), 1) AS avg_result_len,
  MAX(LENGTH(COALESCE(validation_result, ''))) AS max_result_len
FROM q;

.print ''
.print '== Repeated QEMU task rows =='
WITH q AS (
  SELECT *
  FROM iterations
  WHERE agent = 'modernization'
    AND LOWER(
      COALESCE(validation_cmd, '') || ' ' ||
      COALESCE(validation_result, '') || ' ' ||
      COALESCE(notes, '')
    ) LIKE '%qemu%'
)
SELECT
  task_id,
  COUNT(*) AS rows,
  MIN(ts) AS first_ts,
  MAX(ts) AS last_ts,
  SUBSTR(validation_cmd, 1, 90) AS cmd_excerpt
FROM q
GROUP BY task_id
HAVING rows >= 3
ORDER BY rows DESC, task_id
LIMIT 20;

.print ''
.print '== Malformed timestamp side signal =='
SELECT
  ts,
  COUNT(*) AS rows
FROM iterations
WHERE ts NOT LIKE '____-__-__T__:__:__%'
GROUP BY ts
ORDER BY rows DESC, ts;
