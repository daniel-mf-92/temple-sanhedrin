-- Historical validation-evidence / air-gap drift audit.
-- Source DB: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Scope: read-only aggregation over iterations rows; no TempleOS/holyc-inference files modified.

.headers on
.mode column

SELECT
  agent,
  COUNT(*) AS rows,
  MIN(ts) AS first_ts,
  MAX(ts) AS last_ts
FROM iterations
GROUP BY agent
ORDER BY agent;

SELECT
  agent,
  COUNT(*) AS rows,
  SUM(validation_cmd LIKE '%ssh %') AS remote_ssh,
  SUM(validation_cmd LIKE '%azureuser@%') AS azure_ssh,
  SUM(
    validation_cmd LIKE '%ISO unavailable%'
    OR validation_result LIKE '%ISO unavailable%'
    OR validation_result LIKE '%ISO download unavailable%'
    OR validation_result LIKE '%skipped%'
  ) AS iso_skip_rows,
  SUM(validation_cmd LIKE '%-nic none%' OR validation_result LIKE '%-nic none%') AS explicit_nic_none_rows
FROM iterations
WHERE agent IN ('modernization', 'inference')
GROUP BY agent
ORDER BY agent;

SELECT
  DATE(ts) AS day,
  COUNT(*) AS modernization_rows,
  SUM(validation_cmd LIKE '%ssh %') AS remote_ssh_rows,
  SUM(
    validation_result LIKE '%ISO unavailable%'
    OR validation_result LIKE '%skipped%'
    OR validation_result LIKE '%ISO download%'
  ) AS iso_skip_rows
FROM iterations
WHERE agent = 'modernization'
GROUP BY DATE(ts)
ORDER BY day;

SELECT
  agent,
  COUNT(*) AS rows,
  SUM(duration_sec IS NULL) AS null_duration_rows
FROM iterations
WHERE agent IN ('modernization', 'inference', 'sanhedrin')
GROUP BY agent
ORDER BY agent;

SELECT
  agent,
  COUNT(*) AS rows,
  SUM(validation_cmd IS NULL OR TRIM(validation_cmd) = '') AS no_validation_cmd,
  SUM(validation_result IS NULL OR TRIM(validation_result) = '') AS no_validation_result
FROM iterations
GROUP BY agent
ORDER BY agent;

SELECT
  ts,
  task_id,
  validation_cmd,
  validation_result
FROM iterations
WHERE agent = 'modernization'
  AND validation_cmd LIKE '%ssh %'
ORDER BY ts DESC
LIMIT 12;

SELECT
  ts,
  task_id,
  files_changed,
  lines_added,
  validation_result
FROM iterations
WHERE agent = 'modernization'
  AND (
    validation_result LIKE '%ISO unavailable%'
    OR validation_result LIKE '%skipped%'
  )
ORDER BY ts DESC
LIMIT 12;
