-- Historical Sanhedrin severity/status normalization drift audit.
-- Source DB: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Run with:
--   sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-01-sanhedrin-severity-status-drift.sql

.headers on
.mode column

WITH sanhedrin AS (
  SELECT
    id,
    ts,
    task_id,
    status,
    notes,
    CASE
      WHEN lower(coalesce(notes, '')) LIKE '%severity=critical%'
        OR lower(coalesce(notes, '')) LIKE '%severity:critical%' THEN 'critical'
      WHEN lower(coalesce(notes, '')) LIKE '%severity=warning%'
        OR lower(coalesce(notes, '')) LIKE '%severity:warning%' THEN 'warning'
      WHEN lower(coalesce(notes, '')) LIKE '%severity=pass%'
        OR lower(coalesce(notes, '')) LIKE '%severity:pass%' THEN 'pass'
      ELSE 'unlabeled'
    END AS note_severity
  FROM iterations
  WHERE agent = 'sanhedrin'
)
SELECT
  'severity_status_matrix' AS section,
  note_severity,
  status,
  count(*) AS rows,
  min(ts) AS first_ts,
  max(ts) AS last_ts
FROM sanhedrin
GROUP BY note_severity, status
ORDER BY note_severity, status;

WITH sanhedrin AS (
  SELECT
    status,
    notes,
    CASE
      WHEN lower(coalesce(notes, '')) LIKE '%severity=critical%'
        OR lower(coalesce(notes, '')) LIKE '%severity:critical%' THEN 'critical'
      WHEN lower(coalesce(notes, '')) LIKE '%severity=warning%'
        OR lower(coalesce(notes, '')) LIKE '%severity:warning%' THEN 'warning'
      WHEN lower(coalesce(notes, '')) LIKE '%severity=pass%'
        OR lower(coalesce(notes, '')) LIKE '%severity:pass%' THEN 'pass'
      ELSE 'unlabeled'
    END AS note_severity
  FROM iterations
  WHERE agent = 'sanhedrin'
),
totals AS (
  SELECT
    count(*) AS total_rows,
    sum(note_severity = 'critical') AS critical_rows,
    sum(note_severity = 'warning') AS warning_rows,
    sum(note_severity = 'pass') AS pass_labeled_rows,
    sum(note_severity = 'unlabeled') AS unlabeled_rows,
    sum(note_severity = 'warning' AND status = 'pass') AS warning_pass_rows,
    sum(status = 'fail' AND note_severity = 'unlabeled') AS unlabeled_fail_rows,
    sum(status IN ('fail', 'blocked') AND note_severity = 'unlabeled') AS unlabeled_nonpass_rows
  FROM sanhedrin
)
SELECT
  'summary_counts' AS section,
  total_rows,
  critical_rows,
  warning_rows,
  pass_labeled_rows,
  unlabeled_rows,
  warning_pass_rows,
  unlabeled_fail_rows,
  unlabeled_nonpass_rows,
  round(100.0 * warning_pass_rows / total_rows, 1) AS warning_pass_pct,
  round(100.0 * unlabeled_nonpass_rows / total_rows, 1) AS unlabeled_nonpass_pct
FROM totals;

WITH sanhedrin AS (
  SELECT
    id,
    ts,
    task_id,
    status,
    notes,
    CASE
      WHEN lower(coalesce(notes, '')) LIKE '%severity=critical%'
        OR lower(coalesce(notes, '')) LIKE '%severity:critical%' THEN 'critical'
      WHEN lower(coalesce(notes, '')) LIKE '%severity=warning%'
        OR lower(coalesce(notes, '')) LIKE '%severity:warning%' THEN 'warning'
      WHEN lower(coalesce(notes, '')) LIKE '%severity=pass%'
        OR lower(coalesce(notes, '')) LIKE '%severity:pass%' THEN 'pass'
      ELSE 'unlabeled'
    END AS note_severity
  FROM iterations
  WHERE agent = 'sanhedrin'
)
SELECT
  'risk_task_breakdown' AS section,
  task_id,
  status,
  note_severity,
  count(*) AS rows,
  min(ts) AS first_ts,
  max(ts) AS last_ts
FROM sanhedrin
WHERE note_severity IN ('critical', 'warning')
  OR (status IN ('fail', 'blocked') AND note_severity = 'unlabeled')
GROUP BY task_id, status, note_severity
ORDER BY rows DESC, task_id
LIMIT 40;

WITH sanhedrin AS (
  SELECT
    ts,
    status,
    notes,
    CASE
      WHEN lower(coalesce(notes, '')) LIKE '%severity=critical%'
        OR lower(coalesce(notes, '')) LIKE '%severity:critical%' THEN 'critical'
      WHEN lower(coalesce(notes, '')) LIKE '%severity=warning%'
        OR lower(coalesce(notes, '')) LIKE '%severity:warning%' THEN 'warning'
      WHEN lower(coalesce(notes, '')) LIKE '%severity=pass%'
        OR lower(coalesce(notes, '')) LIKE '%severity:pass%' THEN 'pass'
      ELSE 'unlabeled'
    END AS note_severity
  FROM iterations
  WHERE agent = 'sanhedrin'
)
SELECT
  'daily_risk_shape' AS section,
  substr(ts, 1, 10) AS day,
  count(*) AS rows,
  sum(note_severity = 'warning' AND status = 'pass') AS warning_pass_rows,
  sum(note_severity = 'critical') AS critical_rows,
  sum(status = 'fail' AND note_severity = 'unlabeled') AS unlabeled_fail_rows,
  sum(status = 'blocked' AND note_severity = 'unlabeled') AS unlabeled_blocked_rows
FROM sanhedrin
GROUP BY day
ORDER BY day;

WITH sanhedrin AS (
  SELECT
    status,
    notes,
    CASE
      WHEN lower(coalesce(notes, '')) LIKE '%severity=critical%'
        OR lower(coalesce(notes, '')) LIKE '%severity:critical%' THEN 'critical'
      WHEN lower(coalesce(notes, '')) LIKE '%severity=warning%'
        OR lower(coalesce(notes, '')) LIKE '%severity:warning%' THEN 'warning'
      WHEN lower(coalesce(notes, '')) LIKE '%severity=pass%'
        OR lower(coalesce(notes, '')) LIKE '%severity:pass%' THEN 'pass'
      ELSE 'unlabeled'
    END AS note_severity
  FROM iterations
  WHERE agent = 'sanhedrin'
)
SELECT
  'warning_pass_text_signals' AS section,
  count(*) AS warning_pass_rows,
  sum(lower(notes) LIKE '%loops_alive=ok%'
    OR lower(notes) LIKE '%loops_alive(mod=1%'
    OR lower(notes) LIKE '%heartbeat_lt10m=ok%') AS liveness_ok_rows,
  sum(lower(notes) LIKE '%law5%') AS law5_mention_rows,
  sum(lower(notes) LIKE '%pattern%') AS pattern_mention_rows
FROM sanhedrin
WHERE status = 'pass'
  AND note_severity = 'warning';

WITH sanhedrin AS (
  SELECT
    id,
    ts,
    task_id,
    status,
    notes,
    CASE
      WHEN lower(coalesce(notes, '')) LIKE '%severity=critical%'
        OR lower(coalesce(notes, '')) LIKE '%severity:critical%' THEN 'critical'
      WHEN lower(coalesce(notes, '')) LIKE '%severity=warning%'
        OR lower(coalesce(notes, '')) LIKE '%severity:warning%' THEN 'warning'
      WHEN lower(coalesce(notes, '')) LIKE '%severity=pass%'
        OR lower(coalesce(notes, '')) LIKE '%severity:pass%' THEN 'pass'
      ELSE 'unlabeled'
    END AS note_severity
  FROM iterations
  WHERE agent = 'sanhedrin'
)
SELECT
  'representative_rows' AS section,
  id,
  ts,
  task_id,
  status,
  note_severity,
  substr(notes, 1, 180) AS note_excerpt
FROM sanhedrin
WHERE (note_severity = 'warning' AND status = 'pass')
  OR (status IN ('fail', 'blocked') AND note_severity = 'unlabeled')
  OR note_severity = 'critical'
ORDER BY id DESC
LIMIT 20;
