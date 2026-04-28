-- Historical drift audit: temple-central.db violation-recording coverage.
-- Read-only query set used for audits/trends/2026-04-28-temple-central-violation-recording-drift.md.

.headers on
.mode column

SELECT
  agent,
  status,
  COUNT(*) AS rows,
  MIN(ts) AS first_ts,
  MAX(ts) AS last_ts
FROM iterations
GROUP BY agent, status
ORDER BY agent, status;

SELECT
  COUNT(*) AS sanhedrin_rows
FROM iterations
WHERE agent = 'sanhedrin';

SELECT
  COUNT(*) AS violation_rows
FROM violations;

SELECT
  COUNT(*) AS audit_rows,
  SUM(CASE WHEN lower(COALESCE(notes, '')) LIKE '%law%' THEN 1 ELSE 0 END) AS audit_rows_with_law_mentions,
  SUM(CASE WHEN lower(COALESCE(notes, '')) LIKE '%severity=%' THEN 1 ELSE 0 END) AS audit_rows_with_severity_mentions
FROM iterations
WHERE agent = 'sanhedrin'
  AND task_id = 'AUDIT';

SELECT
  COUNT(*) AS audit_rows,
  SUM(CASE WHEN lower(COALESCE(notes, '')) LIKE 'severity=critical%' THEN 1 ELSE 0 END) AS critical_notes,
  SUM(CASE WHEN lower(COALESCE(notes, '')) LIKE 'severity=warning%' THEN 1 ELSE 0 END) AS warning_notes,
  SUM(CASE WHEN lower(COALESCE(notes, '')) LIKE 'severity=pass_with_warning%' THEN 1 ELSE 0 END) AS pass_with_warning_notes,
  SUM(CASE WHEN lower(COALESCE(notes, '')) LIKE 'severity=pass%' THEN 1 ELSE 0 END) AS pass_notes
FROM iterations
WHERE agent = 'sanhedrin'
  AND task_id = 'AUDIT';

SELECT
  status,
  SUM(CASE WHEN lower(COALESCE(notes, '')) LIKE 'severity=critical%' THEN 1 ELSE 0 END) AS critical_notes,
  SUM(CASE WHEN lower(COALESCE(notes, '')) LIKE 'severity=warning%' THEN 1 ELSE 0 END) AS warning_notes,
  COUNT(*) AS rows
FROM iterations
WHERE agent = 'sanhedrin'
  AND task_id = 'AUDIT'
GROUP BY status;

SELECT
  COUNT(*) AS critical_or_warning_audit_rows,
  SUM(CASE WHEN status = 'fail' THEN 1 ELSE 0 END) AS db_fail_status,
  SUM(CASE WHEN status = 'pass' THEN 1 ELSE 0 END) AS db_pass_status
FROM iterations
WHERE agent = 'sanhedrin'
  AND task_id = 'AUDIT'
  AND (
    lower(COALESCE(notes, '')) LIKE 'severity=critical%'
    OR lower(COALESCE(notes, '')) LIKE 'severity=warning%'
    OR lower(COALESCE(notes, '')) LIKE 'severity=pass_with_warning%'
  );

SELECT
  COUNT(*) AS total_iterations,
  SUM(CASE WHEN ts LIKE '____-__-__T__:__:__%' THEN 1 ELSE 0 END) AS iso_like,
  SUM(CASE WHEN ts NOT LIKE '____-__-__T__:__:__%' THEN 1 ELSE 0 END) AS non_iso_like
FROM iterations;

SELECT
  COUNT(*) AS rows_with_null_sqlite_date
FROM iterations
WHERE date(ts) IS NULL;

SELECT
  id,
  ts,
  agent,
  task_id,
  status,
  substr(notes, 1, 120) AS notes
FROM iterations
WHERE ts NOT LIKE '____-__-__T__:__:__%'
ORDER BY id
LIMIT 20;

SELECT
  date(ts) AS day,
  COUNT(*) AS audit_rows,
  SUM(CASE WHEN lower(COALESCE(notes, '')) LIKE 'severity=critical%' THEN 1 ELSE 0 END) AS critical_notes,
  SUM(CASE WHEN lower(COALESCE(notes, '')) LIKE 'severity=warning%' THEN 1 ELSE 0 END) AS warning_notes,
  SUM(CASE WHEN lower(COALESCE(notes, '')) LIKE '%law%' THEN 1 ELSE 0 END) AS law_mentions
FROM iterations
WHERE agent = 'sanhedrin'
  AND task_id = 'AUDIT'
GROUP BY date(ts)
ORDER BY day;
