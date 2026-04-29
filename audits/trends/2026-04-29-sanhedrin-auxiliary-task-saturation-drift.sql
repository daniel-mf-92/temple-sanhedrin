-- Sanhedrin auxiliary-task saturation drift audit.
-- Read-only query pack for:
--   /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
--
-- Usage:
--   sqlite3 /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db \
--     < audits/trends/2026-04-29-sanhedrin-auxiliary-task-saturation-drift.sql

.headers on
.mode column

WITH norm AS (
  SELECT
    id,
    CASE
      WHEN ts GLOB '[0-9][0-9][0-9][0-9]-*' THEN ts
      WHEN ts GLOB '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' THEN datetime(CAST(ts AS integer), 'unixepoch')
      ELSE ts
    END AS ts_norm,
    task_id,
    status,
    notes
  FROM iterations
  WHERE agent = 'sanhedrin'
)
SELECT
  count(*) AS sanhedrin_rows,
  min(ts_norm) AS first_ts,
  max(ts_norm) AS last_ts,
  sum(task_id IN ('EMAIL-CHECK', 'EMAIL_CHECK', 'CLEANUP')) AS auxiliary_rows,
  round(100.0 * sum(task_id IN ('EMAIL-CHECK', 'EMAIL_CHECK', 'CLEANUP')) / count(*), 1) AS auxiliary_pct,
  sum(task_id IN ('EMAIL-CHECK', 'EMAIL_CHECK')) AS email_rows,
  sum(task_id = 'CLEANUP') AS cleanup_rows,
  sum(task_id = 'AUDIT') AS audit_rows
FROM norm;

WITH norm AS (
  SELECT
    id,
    date(CASE
      WHEN ts GLOB '[0-9][0-9][0-9][0-9]-*' THEN ts
      WHEN ts GLOB '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' THEN datetime(CAST(ts AS integer), 'unixepoch')
      ELSE ts
    END) AS d,
    task_id
  FROM iterations
  WHERE agent = 'sanhedrin'
)
SELECT
  d,
  count(*) AS sanhedrin_rows,
  sum(task_id = 'AUDIT') AS audit_rows,
  sum(task_id IN ('EMAIL-CHECK', 'EMAIL_CHECK', 'CLEANUP')) AS auxiliary_rows,
  round(100.0 * sum(task_id IN ('EMAIL-CHECK', 'EMAIL_CHECK', 'CLEANUP')) / count(*), 1) AS auxiliary_pct,
  round(1.0 * sum(task_id IN ('EMAIL-CHECK', 'EMAIL_CHECK', 'CLEANUP')) / nullif(sum(task_id = 'AUDIT'), 0), 2) AS auxiliary_per_audit
FROM norm
GROUP BY d
ORDER BY d;

WITH norm AS (
  SELECT
    id,
    date(CASE
      WHEN ts GLOB '[0-9][0-9][0-9][0-9]-*' THEN ts
      WHEN ts GLOB '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' THEN datetime(CAST(ts AS integer), 'unixepoch')
      ELSE ts
    END) AS d,
    task_id,
    notes
  FROM iterations
  WHERE agent = 'sanhedrin'
)
SELECT
  d,
  count(*) AS email_rows,
  sum(notes LIKE '%missing MARTA_GOOGLE_CLIENT_ID%' OR notes LIKE '%missing MARTA_GOOGLE_CLIENT_SECRET%') AS missing_credential_rows
FROM norm
WHERE task_id IN ('EMAIL-CHECK', 'EMAIL_CHECK')
GROUP BY d
ORDER BY d;

WITH norm AS (
  SELECT
    id,
    CASE
      WHEN ts GLOB '[0-9][0-9][0-9][0-9]-*' THEN ts
      WHEN ts GLOB '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' THEN datetime(CAST(ts AS integer), 'unixepoch')
      ELSE ts
    END AS ts_norm,
    task_id,
    notes
  FROM iterations
  WHERE agent = 'sanhedrin'
),
missing AS (
  SELECT *
  FROM norm
  WHERE task_id IN ('EMAIL-CHECK', 'EMAIL_CHECK')
    AND (notes LIKE '%missing MARTA_GOOGLE_CLIENT_ID%' OR notes LIKE '%missing MARTA_GOOGLE_CLIENT_SECRET%')
)
SELECT
  count(*) AS missing_credential_rows,
  min(ts_norm) AS first_ts,
  max(ts_norm) AS last_ts,
  round((julianday(max(ts_norm)) - julianday(min(ts_norm))) * 24, 1) AS span_hours
FROM missing;

SELECT
  count(*) AS cleanup_rows,
  sum(
    lower(notes) LIKE '%deleted%0%'
    OR lower(notes) LIKE '%count=0%'
    OR notes = 'cleanup_old_audit_md_deleted=0'
  ) AS zero_semantic_rows,
  sum(NOT (
    lower(notes) LIKE '%deleted%0%'
    OR lower(notes) LIKE '%count=0%'
    OR notes = 'cleanup_old_audit_md_deleted=0'
  )) AS other_rows,
  min(ts) AS first_ts,
  max(ts) AS last_ts
FROM iterations
WHERE agent = 'sanhedrin'
  AND task_id = 'CLEANUP';

SELECT
  id,
  ts,
  notes
FROM iterations
WHERE agent = 'sanhedrin'
  AND task_id = 'CLEANUP'
  AND NOT (
    lower(notes) LIKE '%deleted%0%'
    OR lower(notes) LIKE '%count=0%'
    OR notes = 'cleanup_old_audit_md_deleted=0'
  )
ORDER BY id;

WITH norm AS (
  SELECT
    date(CASE
      WHEN ts GLOB '[0-9][0-9][0-9][0-9]-*' THEN ts
      WHEN ts GLOB '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' THEN datetime(CAST(ts AS integer), 'unixepoch')
      ELSE ts
    END) AS d,
    task_id,
    notes
  FROM iterations
  WHERE agent = 'sanhedrin'
)
SELECT
  d,
  count(*) AS audit_rows_with_email_blocked
FROM norm
WHERE task_id = 'AUDIT'
  AND notes LIKE '%email_check=blocked_missing_marta_google_oauth%'
GROUP BY d
ORDER BY d;
