-- Historical trend audit: builder line-delta accounting drift.
-- Read-only target:
--   /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
--
-- Usage:
--   sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-30-builder-line-delta-accounting-drift.sql

.headers on
.mode column

WITH builder AS (
  SELECT
    *,
    lines_added + lines_removed AS line_delta,
    LOWER(COALESCE(files_changed, '')) AS files_lc,
    LOWER(COALESCE(notes, '')) AS notes_lc
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
)
SELECT
  agent,
  COUNT(*) AS rows,
  SUM(line_delta = 0) AS zero_delta_rows,
  SUM(line_delta = 0 AND (files_changed LIKE '%,%' OR files_changed LIKE '%;%')) AS zero_delta_multi_file_rows,
  SUM(line_delta = 0 AND files_lc LIKE '%.hc%') AS zero_delta_hc_rows,
  SUM(line_delta = 0 AND files_lc LIKE '%master_tasks.md%') AS zero_delta_master_tasks_rows,
  SUM(line_delta = 0 AND (
    notes_lc LIKE '%implemented%' OR
    notes_lc LIKE '%added%' OR
    notes_lc LIKE '%fixed%' OR
    notes_lc LIKE '%hardened%' OR
    notes_lc LIKE '%removed%' OR
    notes_lc LIKE '%deduplicated%'
  )) AS zero_delta_change_claim_rows,
  SUM(line_delta BETWEEN 1 AND 3) AS tiny_delta_1_to_3_rows,
  SUM(line_delta <= 3) AS delta_0_to_3_rows,
  SUM(line_delta >= 1000) AS huge_delta_ge_1000_rows,
  MAX(line_delta) AS max_line_delta,
  ROUND(AVG(line_delta), 2) AS avg_line_delta
FROM builder
GROUP BY agent
ORDER BY agent;

WITH builder AS (
  SELECT
    *,
    lines_added + lines_removed AS line_delta
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
)
SELECT
  SUBSTR(ts, 1, 10) AS day,
  agent,
  COUNT(*) AS rows,
  SUM(line_delta = 0) AS zero_delta_rows,
  SUM(line_delta BETWEEN 1 AND 3) AS tiny_delta_1_to_3_rows,
  SUM(line_delta >= 1000) AS huge_delta_ge_1000_rows
FROM builder
GROUP BY day, agent
ORDER BY day, agent;

WITH builder AS (
  SELECT
    *,
    lines_added + lines_removed AS line_delta,
    LOWER(COALESCE(notes, '')) AS notes_lc
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
)
SELECT
  agent,
  ts,
  task_id,
  lines_added,
  lines_removed,
  LENGTH(files_changed) AS files_changed_len,
  files_changed,
  validation_result,
  SUBSTR(notes, 1, 140) AS notes
FROM builder
WHERE line_delta = 0
ORDER BY ts, agent, task_id;

WITH builder AS (
  SELECT
    *,
    lines_added + lines_removed AS line_delta
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
)
SELECT
  agent,
  task_id,
  ts,
  lines_added,
  lines_removed,
  files_changed
FROM builder
ORDER BY line_delta DESC, ts
LIMIT 20;
