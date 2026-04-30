-- Historical trend audit: Sanhedrin status evidence null-field drift.
-- Read-only target:
--   /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db

.headers on
.mode column

WITH s AS (
  SELECT *
  FROM iterations
  WHERE agent = 'sanhedrin'
)
SELECT
  COUNT(*) AS total_sanhedrin_rows,
  SUM(validation_cmd IS NULL OR TRIM(validation_cmd) = '') AS missing_cmd,
  SUM(validation_result IS NULL OR TRIM(validation_result) = '') AS missing_result,
  SUM(error_msg IS NULL OR TRIM(error_msg) = '') AS missing_error_msg,
  SUM(duration_sec IS NULL) AS missing_duration,
  SUM(files_changed IS NULL OR TRIM(files_changed) = '') AS missing_files_changed,
  SUM(status IN ('fail', 'blocked') AND (error_msg IS NULL OR TRIM(error_msg) = '')) AS nonpass_missing_error
FROM s;

SELECT
  status,
  COUNT(*) AS rows,
  SUM(notes IS NULL OR TRIM(notes) = '') AS missing_notes,
  SUM(files_changed IS NULL OR TRIM(files_changed) = '') AS missing_files_changed,
  SUM(duration_sec IS NULL) AS missing_duration,
  MIN(ts) AS first_ts,
  MAX(ts) AS last_ts
FROM iterations
WHERE agent = 'sanhedrin'
GROUP BY status
ORDER BY status;

SELECT
  status,
  COUNT(*) AS rows,
  SUM(LOWER(notes) LIKE '%network%') AS network_note_rows,
  SUM(LOWER(notes) LIKE '%qemu%') AS qemu_note_rows,
  SUM(LOWER(notes) LIKE '%nic none%' OR LOWER(notes) LIKE '%-net none%') AS airgap_note_rows,
  SUM(LOWER(notes) LIKE '%error%' OR LOWER(notes) LIKE '%fail%' OR LOWER(notes) LIKE '%blocked%') AS negative_note_rows
FROM iterations
WHERE agent = 'sanhedrin'
GROUP BY status
ORDER BY status;

SELECT
  task_id,
  status,
  COUNT(*) AS rows,
  SUM(validation_cmd IS NULL OR TRIM(validation_cmd) = '') AS missing_cmd,
  SUM(validation_result IS NULL OR TRIM(validation_result) = '') AS missing_result,
  SUM(error_msg IS NULL OR TRIM(error_msg) = '') AS missing_error_msg,
  SUM(files_changed IS NULL OR TRIM(files_changed) = '') AS missing_files_changed
FROM iterations
WHERE agent = 'sanhedrin'
  AND task_id IN (
    'AUDIT',
    'LAW-CHECK',
    'LIVENESS',
    'VM-COMPILE',
    'CI-CHECK',
    'CI-TEMPLEOS',
    'CI-INFERENCE',
    'EMAIL-CHECK'
  )
GROUP BY task_id, status
ORDER BY task_id, status;

SELECT
  status,
  task_id,
  COUNT(*) AS rows,
  MIN(ts) AS first_ts,
  MAX(ts) AS last_ts
FROM iterations
WHERE agent = 'sanhedrin'
GROUP BY status, task_id
ORDER BY status, rows DESC, task_id
LIMIT 80;

SELECT
  status,
  task_id,
  ts,
  SUBSTR(notes, 1, 180) AS notes
FROM iterations
WHERE agent = 'sanhedrin'
  AND status IN ('fail', 'blocked')
ORDER BY ts
LIMIT 60;
