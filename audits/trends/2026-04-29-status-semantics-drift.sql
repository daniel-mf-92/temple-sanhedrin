-- Historical status-semantics drift audit, read-only against temple-central.db.
-- Source DB: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Scope: iterations rows for builder agents only; no TempleOS/holyc-inference files modified.
-- Run from temple-sanhedrin:
--   sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-29-status-semantics-drift.sql

.headers on
.mode column

SELECT
  agent,
  status,
  COUNT(*) AS rows,
  MIN(ts) AS first_ts,
  MAX(ts) AS last_ts
FROM iterations
WHERE agent IN ('modernization', 'inference')
GROUP BY agent, status
ORDER BY agent, status;

WITH builder AS (
  SELECT
    *,
    LOWER(COALESCE(validation_result, '')) AS vr,
    LOWER(COALESCE(notes, '')) AS nt
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
)
SELECT
  agent,
  COUNT(*) AS rows,
  SUM(status = 'pass') AS pass_rows,
  SUM(status != 'pass') AS nonpass_rows,
  SUM(status = 'pass' AND (vr LIKE '%skip%' OR nt LIKE '%skip%')) AS pass_with_skip_signal,
  SUM(status = 'pass' AND (vr LIKE '%qemu%skip%' OR nt LIKE '%qemu%skip%' OR vr LIKE '%skip%qemu%' OR nt LIKE '%skip%qemu%')) AS pass_with_qemu_skip_signal,
  SUM(status = 'pass' AND (vr LIKE '%iso%unavailable%' OR nt LIKE '%iso%unavailable%' OR vr LIKE '%iso%blocked%' OR nt LIKE '%iso%blocked%' OR vr LIKE '%iso fetch%' OR nt LIKE '%iso fetch%')) AS pass_with_iso_unavailable_or_blocked,
  SUM(status = 'pass' AND (vr LIKE '%queue remains%unchecked%' OR nt LIKE '%queue remains%unchecked%' OR vr LIKE '%queue depth%unchecked%' OR nt LIKE '%queue depth%unchecked%')) AS pass_with_unchecked_queue_signal
FROM builder
GROUP BY agent
ORDER BY agent;

WITH modernization AS (
  SELECT
    *,
    LOWER(COALESCE(validation_result, '')) AS vr,
    LOWER(COALESCE(notes, '')) AS nt
  FROM iterations
  WHERE agent = 'modernization'
)
SELECT
  COUNT(*) AS modernization_rows,
  SUM(status = 'pass' AND (vr LIKE '%iso%unavailable%' OR nt LIKE '%iso%unavailable%' OR vr LIKE '%iso%blocked%' OR nt LIKE '%iso%blocked%' OR vr LIKE '%iso fetch%' OR nt LIKE '%iso fetch%')) AS pass_iso_unavailable_or_blocked,
  SUM(status = 'pass' AND (vr LIKE '%qemu%skip%' OR nt LIKE '%qemu%skip%' OR vr LIKE '%skip%qemu%' OR nt LIKE '%skip%qemu%')) AS pass_qemu_skip,
  SUM(status = 'pass' AND (vr LIKE '%compile%skip%' OR nt LIKE '%compile%skip%' OR vr LIKE '%skip%compile%' OR nt LIKE '%skip%compile%')) AS pass_compile_skip,
  SUM(status = 'pass' AND (vr LIKE '%smoke pass%' OR nt LIKE '%smoke pass%')) AS pass_with_smoke_pass_signal
FROM modernization;

WITH builder AS (
  SELECT
    *,
    LOWER(COALESCE(validation_result, '')) AS vr,
    LOWER(COALESCE(notes, '')) AS nt
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
)
SELECT
  SUBSTR(ts, 1, 10) AS day,
  agent,
  COUNT(*) AS rows,
  SUM(status = 'pass') AS pass_rows,
  SUM(status != 'pass') AS nonpass_rows,
  SUM(status = 'pass' AND (vr LIKE '%skip%' OR nt LIKE '%skip%')) AS pass_with_skip_signal,
  SUM(status = 'pass' AND (vr LIKE '%iso%unavailable%' OR nt LIKE '%iso%unavailable%' OR vr LIKE '%iso%blocked%' OR nt LIKE '%iso%blocked%' OR vr LIKE '%iso fetch%' OR nt LIKE '%iso fetch%')) AS pass_with_iso_unavailable_or_blocked
FROM builder
GROUP BY day, agent
ORDER BY day, agent;

WITH builder AS (
  SELECT
    *,
    LOWER(COALESCE(validation_result, '')) AS vr,
    LOWER(COALESCE(notes, '')) AS nt
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
)
SELECT
  agent,
  ts,
  task_id,
  status,
  SUBSTR(validation_result, 1, 90) AS validation_result,
  SUBSTR(notes, 1, 140) AS notes
FROM builder
WHERE status = 'pass'
  AND (vr LIKE '%skip%' OR nt LIKE '%skip%')
ORDER BY ts DESC
LIMIT 12;

