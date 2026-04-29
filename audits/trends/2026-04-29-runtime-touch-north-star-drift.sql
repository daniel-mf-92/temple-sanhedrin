-- Historical runtime-touch and North Star evidence drift audit.
-- Source DB: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Scope: historical/retroactive only. No live liveness checks, QEMU, VM, or
-- trinity source modifications are performed by this query pack.
--
-- Run from temple-sanhedrin:
--   sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-29-runtime-touch-north-star-drift.sql

.headers on
.mode column

-- Pass rows that report no churn or incomplete validation evidence.
WITH b AS (
  SELECT
    *,
    COALESCE(lines_added, 0) + COALESCE(lines_removed, 0) AS churn,
    LOWER(COALESCE(files_changed, '')) AS files,
    LOWER(COALESCE(validation_cmd, '')) AS vcmd,
    LOWER(COALESCE(validation_result, '')) AS vres
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
)
SELECT
  agent,
  COUNT(*) AS rows,
  SUM(status = 'pass') AS pass_rows,
  SUM(status = 'pass' AND churn = 0) AS pass_zero_churn,
  ROUND(100.0 * SUM(status = 'pass' AND churn = 0) / NULLIF(SUM(status = 'pass'), 0), 1) AS pass_zero_pct,
  SUM(status = 'pass' AND TRIM(files) = '') AS pass_no_files,
  SUM(status = 'pass' AND TRIM(vcmd) = '') AS pass_no_validation_cmd,
  SUM(status = 'pass' AND TRIM(vres) = '') AS pass_no_validation_result
FROM b
GROUP BY agent
ORDER BY agent;

-- North Star evidence recorded in validation commands/results/notes.
SELECT
  agent,
  COUNT(*) AS rows,
  SUM(LOWER(COALESCE(validation_cmd, '')) GLOB '*north-star-e2e*') AS north_star_cmd_rows,
  MIN(CASE WHEN LOWER(COALESCE(validation_cmd, '')) GLOB '*north-star-e2e*' THEN ts END) AS first_ns,
  MAX(CASE WHEN LOWER(COALESCE(validation_cmd, '')) GLOB '*north-star-e2e*' THEN ts END) AS last_ns
FROM iterations
WHERE agent IN ('modernization', 'inference')
GROUP BY agent
ORDER BY agent;

SELECT
  agent,
  COUNT(*) AS rows,
  SUM(LOWER(COALESCE(notes, '') || ' ' || COALESCE(validation_result, '')) GLOB '*north*star*') AS north_star_explanation_rows,
  SUM(LOWER(COALESCE(notes, '') || ' ' || COALESCE(validation_result, '')) GLOB '*meaningful*') AS meaningful_rows,
  SUM(LOWER(COALESCE(notes, '') || ' ' || COALESCE(validation_result, '')) GLOB '*on-path*') AS on_path_rows
FROM iterations
WHERE agent IN ('modernization', 'inference')
GROUP BY agent
ORDER BY agent;

-- Runtime-touch proxy by agent. This is deliberately conservative: HolyC file
-- touches count as runtime touches for either builder, and known TempleOS core
-- directories or holyc-inference src/ also count.
WITH base AS (
  SELECT
    *,
    LOWER(COALESCE(files_changed, '')) AS files,
    LOWER(COALESCE(validation_cmd, '')) AS cmd,
    COALESCE(lines_added, 0) + COALESCE(lines_removed, 0) AS churn
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
),
runtime AS (
  SELECT
    *,
    CASE
      WHEN (
        agent = 'modernization'
        AND (
          files GLOB '*kernel/*' OR files GLOB '*adam/*' OR files GLOB '*apps/*' OR
          files GLOB '*compiler/*' OR files GLOB '*0000boot/*' OR files GLOB '*.hc*'
        )
      )
      OR (
        agent = 'inference'
        AND (files GLOB '*src/*' OR files GLOB '*.hc*')
      )
      THEN 1
      ELSE 0
    END AS runtime_touch,
    CASE WHEN files GLOB '*master_tasks.md*' THEN 1 ELSE 0 END AS task_touch,
    CASE WHEN files GLOB '*automation/*' OR files GLOB '*tests/*' THEN 1 ELSE 0 END AS harness_touch
  FROM base
)
SELECT
  agent,
  COUNT(*) AS rows,
  SUM(runtime_touch) AS runtime_touch_rows,
  SUM(NOT runtime_touch) AS no_runtime_touch_rows,
  ROUND(100.0 * SUM(NOT runtime_touch) / COUNT(*), 1) AS no_runtime_touch_pct,
  SUM(NOT runtime_touch AND task_touch) AS no_runtime_with_task_file,
  SUM(NOT runtime_touch AND harness_touch) AS no_runtime_with_harness,
  SUM(NOT runtime_touch AND churn < 50) AS no_runtime_lt50_churn
FROM runtime
GROUP BY agent
ORDER BY agent;

-- Daily trend for non-runtime-touch rows.
WITH base AS (
  SELECT
    *,
    DATE(ts) AS day,
    LOWER(COALESCE(files_changed, '')) AS files,
    COALESCE(lines_added, 0) + COALESCE(lines_removed, 0) AS churn
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
),
runtime AS (
  SELECT
    *,
    CASE
      WHEN (
        agent = 'modernization'
        AND (
          files GLOB '*kernel/*' OR files GLOB '*adam/*' OR files GLOB '*apps/*' OR
          files GLOB '*compiler/*' OR files GLOB '*0000boot/*' OR files GLOB '*.hc*'
        )
      )
      OR (
        agent = 'inference'
        AND (files GLOB '*src/*' OR files GLOB '*.hc*')
      )
      THEN 1
      ELSE 0
    END AS runtime_touch
  FROM base
)
SELECT
  day,
  agent,
  COUNT(*) AS rows,
  SUM(NOT runtime_touch) AS no_runtime_rows,
  ROUND(100.0 * SUM(NOT runtime_touch) / COUNT(*), 1) AS no_runtime_pct
FROM runtime
GROUP BY day, agent
ORDER BY day, agent;

-- Representative low-churn, non-runtime-touch pass rows.
WITH base AS (
  SELECT
    *,
    LOWER(COALESCE(files_changed, '')) AS files,
    COALESCE(lines_added, 0) + COALESCE(lines_removed, 0) AS churn
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
),
runtime AS (
  SELECT
    *,
    CASE
      WHEN (
        agent = 'modernization'
        AND (
          files GLOB '*kernel/*' OR files GLOB '*adam/*' OR files GLOB '*apps/*' OR
          files GLOB '*compiler/*' OR files GLOB '*0000boot/*' OR files GLOB '*.hc*'
        )
      )
      OR (
        agent = 'inference'
        AND (files GLOB '*src/*' OR files GLOB '*.hc*')
      )
      THEN 1
      ELSE 0
    END AS runtime_touch
  FROM base
)
SELECT
  agent,
  ts,
  task_id,
  churn,
  SUBSTR(files_changed, 1, 88) AS files,
  SUBSTR(validation_cmd, 1, 88) AS validation_cmd,
  SUBSTR(validation_result, 1, 88) AS validation_result
FROM runtime
WHERE status = 'pass'
  AND NOT runtime_touch
  AND churn < 50
ORDER BY ts
LIMIT 20;
