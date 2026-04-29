-- Historical law-register / violation-sink drift audit.
-- Read-only source:
--   /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
--
-- Usage:
--   sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-29-law-register-violation-sink-drift.sql

SELECT
  COUNT(*) AS iteration_rows,
  SUM(CASE WHEN status = 'pass' THEN 1 ELSE 0 END) AS pass_rows,
  SUM(CASE WHEN status = 'fail' THEN 1 ELSE 0 END) AS fail_rows,
  SUM(CASE WHEN status = 'blocked' THEN 1 ELSE 0 END) AS blocked_rows,
  SUM(CASE WHEN status = 'skip' THEN 1 ELSE 0 END) AS skip_rows
FROM iterations;

SELECT
  agent,
  status,
  COUNT(*) AS rows
FROM iterations
GROUP BY agent, status
ORDER BY agent, status;

SELECT
  COUNT(*) AS violation_rows
FROM violations;

SELECT
  l.id,
  l.name AS db_name,
  CASE l.id
    WHEN 4 THEN 'Integer Purity + Identifier Compounding Ban'
    WHEN 5 THEN 'No Busywork + North Star Discipline'
    WHEN 6 THEN 'Queue Health + No Self-Generated Queue Items'
    WHEN 7 THEN 'Process Liveness + Blocker Escalation'
    ELSE l.name
  END AS laws_md_scope,
  CASE
    WHEN l.id IN (4, 5, 6, 7) THEN 'ambiguous/reused in LAWS.md'
    ELSE 'single current heading'
  END AS register_status,
  COUNT(v.id) AS violation_rows
FROM laws l
LEFT JOIN violations v ON v.law_id = l.id
GROUP BY l.id, l.name
ORDER BY l.id;

SELECT
  COUNT(*) AS sanhedrin_audit_rows,
  SUM(CASE WHEN notes LIKE '%Severity=%' OR notes LIKE '%severity=%' THEN 1 ELSE 0 END) AS rows_with_severity_notes,
  SUM(CASE WHEN notes LIKE '%no_critical_violations%' THEN 1 ELSE 0 END) AS rows_claiming_no_critical,
  SUM(CASE WHEN notes LIKE '%law4%' OR notes LIKE '%LAW-4%' THEN 1 ELSE 0 END) AS rows_with_law4_text,
  SUM(CASE WHEN notes LIKE '%law6%' OR notes LIKE '%LAW-6%' THEN 1 ELSE 0 END) AS rows_with_law6_text
FROM iterations
WHERE agent = 'sanhedrin'
  AND task_id = 'AUDIT';
