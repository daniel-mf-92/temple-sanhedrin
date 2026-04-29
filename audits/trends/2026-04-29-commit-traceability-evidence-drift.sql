-- Historical commit-traceability evidence drift audit.
-- Source DB: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Scope: historical/retroactive only. No live liveness checks, QEMU, VM, or
-- trinity source modifications are performed by this query pack.
--
-- Run from temple-sanhedrin:
--   sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-29-commit-traceability-evidence-drift.sql

.headers on
.mode column

-- Confirm that the iteration table has no commit SHA/ref column.
PRAGMA table_info(iterations);

-- Loose evidence scan. "commit" is intentionally only a weak signal because
-- inference notes often use it as a data-structure verb rather than a git noun.
WITH b AS (
  SELECT
    *,
    LOWER(COALESCE(files_changed, '')) AS files,
    LOWER(COALESCE(validation_cmd, '')) AS cmd,
    LOWER(COALESCE(validation_result, '')) AS result,
    LOWER(COALESCE(notes, '')) AS n
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
),
flags AS (
  SELECT
    *,
    CASE
      WHEN cmd GLOB '*git rev-parse*'
        OR cmd GLOB '*git show*'
        OR cmd GLOB '*git log*'
        OR cmd GLOB '*git diff*'
        OR result GLOB '*commit*'
        OR n GLOB '*commit*'
      THEN 1 ELSE 0
    END AS weak_git_evidence,
    CASE
      WHEN (cmd || ' ' || result || ' ' || n || ' ' || files)
        GLOB '*[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]*'
      THEN 1 ELSE 0
    END AS weak_hexish_evidence,
    CASE WHEN files GLOB '*,*' OR files GLOB '*;*' THEN 1 ELSE 0 END AS multi_file,
    CASE WHEN task_id GLOB '*/*' OR task_id GLOB '*,*' OR task_id GLOB '* *' THEN 1 ELSE 0 END AS compound_task_id
  FROM b
)
SELECT
  agent,
  COUNT(*) AS rows,
  MIN(ts) AS first_ts,
  MAX(ts) AS last_ts,
  SUM(weak_git_evidence) AS weak_git_evidence_rows,
  SUM(weak_hexish_evidence) AS weak_hexish_rows,
  SUM(weak_git_evidence OR weak_hexish_evidence) AS weak_trace_rows,
  ROUND(100.0 * SUM(weak_git_evidence OR weak_hexish_evidence) / COUNT(*), 2) AS weak_trace_pct,
  SUM(compound_task_id) AS compound_task_rows,
  SUM(multi_file) AS multi_file_rows
FROM flags
GROUP BY agent
ORDER BY agent;

-- Reused task IDs make task_id unsuitable as a commit-identity substitute.
WITH task_counts AS (
  SELECT
    agent,
    task_id,
    COUNT(*) AS rows,
    MIN(ts) AS first_ts,
    MAX(ts) AS last_ts
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
  GROUP BY agent, task_id
)
SELECT
  agent,
  COUNT(*) AS distinct_task_ids,
  SUM(rows > 1) AS reused_task_ids,
  MAX(rows) AS max_rows_for_one_task,
  ROUND(100.0 * SUM(rows > 1) / COUNT(*), 1) AS reused_task_pct
FROM task_counts
GROUP BY agent
ORDER BY agent;

-- Highest-reuse task IDs.
WITH task_counts AS (
  SELECT
    agent,
    task_id,
    COUNT(*) AS rows,
    MIN(ts) AS first_ts,
    MAX(ts) AS last_ts
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
  GROUP BY agent, task_id
  HAVING COUNT(*) > 1
)
SELECT
  agent,
  task_id,
  rows,
  first_ts,
  last_ts
FROM task_counts
ORDER BY rows DESC, agent, task_id
LIMIT 20;

-- Daily weak traceability trend.
WITH b AS (
  SELECT
    DATE(ts) AS day,
    agent,
    CASE
      WHEN LOWER(COALESCE(validation_cmd, '')) GLOB '*git rev-parse*'
        OR LOWER(COALESCE(validation_cmd, '')) GLOB '*git show*'
        OR LOWER(COALESCE(validation_cmd, '')) GLOB '*git log*'
        OR LOWER(COALESCE(validation_cmd, '')) GLOB '*git diff*'
        OR LOWER(COALESCE(validation_result, '')) GLOB '*commit*'
        OR LOWER(COALESCE(notes, '')) GLOB '*commit*'
        OR LOWER(COALESCE(validation_cmd, '') || ' ' || COALESCE(validation_result, '') || ' ' || COALESCE(notes, '') || ' ' || COALESCE(files_changed, ''))
          GLOB '*[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]*'
      THEN 1 ELSE 0
    END AS weak_trace
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
)
SELECT
  day,
  agent,
  COUNT(*) AS rows,
  SUM(weak_trace) AS weak_traced_rows,
  ROUND(100.0 * SUM(weak_trace) / COUNT(*), 1) AS weak_traced_pct
FROM b
GROUP BY day, agent
ORDER BY day, agent;
