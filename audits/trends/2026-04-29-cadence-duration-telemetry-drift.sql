-- Historical cadence/duration telemetry drift audit.
-- Read-only query pack for:
--   /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- No QEMU, VM, or trinity source operation is performed by this query pack.

.headers on
.mode column

-- Builder row coverage and missing duration telemetry.
SELECT
  agent,
  COUNT(*) AS rows,
  MIN(ts) AS first_ts,
  MAX(ts) AS last_ts,
  SUM(duration_sec IS NULL) AS null_duration,
  SUM(validation_cmd IS NULL OR TRIM(validation_cmd) = '') AS missing_validation_cmd,
  SUM(validation_result IS NULL OR TRIM(validation_result) = '') AS missing_validation_result
FROM iterations
WHERE agent IN ('modernization', 'inference')
GROUP BY agent;

-- Inter-arrival cadence by agent. This is not live liveness watching; it is
-- historical row-spacing analysis over already-recorded rows.
WITH ordered AS (
  SELECT
    agent,
    ts,
    task_id,
    lines_added + lines_removed AS churn,
    unixepoch(ts) - unixepoch(LAG(ts) OVER (PARTITION BY agent ORDER BY ts, id)) AS gap_sec
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
)
SELECT
  agent,
  COUNT(*) AS rows,
  SUM(gap_sec IS NOT NULL AND gap_sec < 60) AS gaps_lt_60s,
  SUM(gap_sec IS NOT NULL AND gap_sec < 120) AS gaps_lt_120s,
  SUM(gap_sec IS NOT NULL AND gap_sec < 300) AS gaps_lt_300s,
  MIN(gap_sec) AS min_gap_sec,
  ROUND(AVG(gap_sec), 1) AS avg_gap_sec
FROM ordered
GROUP BY agent;

-- Daily burst shape.
WITH ordered AS (
  SELECT
    agent,
    DATE(ts) AS day,
    ts,
    task_id,
    unixepoch(ts) - unixepoch(LAG(ts) OVER (PARTITION BY agent ORDER BY ts, id)) AS gap_sec
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
)
SELECT
  day,
  agent,
  COUNT(*) AS rows,
  SUM(gap_sec IS NOT NULL AND gap_sec < 60) AS gaps_lt_60s,
  SUM(gap_sec IS NOT NULL AND gap_sec < 120) AS gaps_lt_120s,
  MIN(gap_sec) AS min_gap_sec
FROM ordered
GROUP BY day, agent
ORDER BY day, agent;

-- Same-second timestamp collisions.
SELECT
  agent,
  COUNT(*) AS timestamp_groups,
  SUM(rows) AS rows_in_duplicate_ts,
  MAX(rows) AS max_same_ts
FROM (
  SELECT agent, ts, COUNT(*) AS rows
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
  GROUP BY agent, ts
  HAVING COUNT(*) > 1
)
GROUP BY agent;

-- Representative duplicate timestamp groups.
SELECT
  agent,
  ts,
  COUNT(*) AS rows,
  GROUP_CONCAT(task_id, ', ') AS tasks,
  SUM(lines_added + lines_removed) AS churn
FROM iterations
WHERE agent IN ('modernization', 'inference')
GROUP BY agent, ts
HAVING COUNT(*) > 1
ORDER BY rows DESC, churn DESC
LIMIT 20;

-- Burst rows with meaningful churn.
WITH ordered AS (
  SELECT
    agent,
    ts,
    task_id,
    lines_added + lines_removed AS churn,
    unixepoch(ts) - unixepoch(LAG(ts) OVER (PARTITION BY agent ORDER BY ts, id)) AS gap_sec
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
)
SELECT
  agent,
  COUNT(*) AS burst_rows,
  SUM(churn) AS burst_churn,
  MAX(churn) AS max_churn,
  SUM(churn >= 100) AS churn_ge_100,
  SUM(churn >= 250) AS churn_ge_250,
  SUM(churn >= 500) AS churn_ge_500,
  SUM(churn >= 1000) AS churn_ge_1000
FROM ordered
WHERE gap_sec IS NOT NULL AND gap_sec < 60
GROUP BY agent;

-- Repeated-task bursts.
WITH ordered AS (
  SELECT
    agent,
    ts,
    task_id,
    unixepoch(ts) - unixepoch(LAG(ts) OVER (PARTITION BY agent ORDER BY ts, id)) AS gap_sec,
    LAG(task_id) OVER (PARTITION BY agent ORDER BY ts, id) AS prev_task
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
)
SELECT
  agent,
  COUNT(*) AS repeated_task_bursts
FROM ordered
WHERE gap_sec IS NOT NULL
  AND gap_sec < 60
  AND task_id = prev_task
GROUP BY agent;

-- Representative sub-20-second rows.
WITH ordered AS (
  SELECT
    agent,
    ts,
    task_id,
    files_changed,
    lines_added + lines_removed AS churn,
    validation_result,
    unixepoch(ts) - unixepoch(LAG(ts) OVER (PARTITION BY agent ORDER BY ts, id)) AS gap_sec
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
)
SELECT
  agent,
  ts,
  task_id,
  gap_sec,
  churn,
  SUBSTR(files_changed, 1, 70) AS files,
  SUBSTR(validation_result, 1, 90) AS result
FROM ordered
WHERE gap_sec IS NOT NULL
  AND gap_sec < 20
ORDER BY gap_sec ASC, ts
LIMIT 20;
