-- Historical remote host-key bypass validation drift.
-- Read with:
-- sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-02-remote-host-key-bypass-validation-drift.sql

.headers on
.mode column

WITH builder AS (
  SELECT *
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
),
classified AS (
  SELECT
    *,
    (
      COALESCE(validation_cmd, '') LIKE '%ssh %'
      OR COALESCE(validation_cmd, '') LIKE '%scp %'
      OR COALESCE(validation_cmd, '') LIKE '%azureuser@%'
      OR COALESCE(validation_cmd, '') LIKE '%52.157.85.234%'
    ) AS remote_row,
    COALESCE(validation_cmd, '') LIKE '%StrictHostKeyChecking=no%' AS strict_host_disabled,
    COALESCE(validation_cmd, '') LIKE '%scp %' AS scp_row,
    COALESCE(validation_cmd, '') LIKE '%azureuser@52.157.85.234%' AS azure_ip_row,
    (
      COALESCE(validation_cmd, '') LIKE '%ssh-keyscan%'
      OR COALESCE(validation_cmd, '') LIKE '%known_hosts%'
    ) AS host_key_pin_row,
    (
      COALESCE(validation_cmd, '') LIKE '%qemu%'
      OR COALESCE(validation_result, '') LIKE '%qemu%'
      OR COALESCE(notes, '') LIKE '%qemu%'
    ) AS qemu_row,
    (
      COALESCE(validation_cmd, '') LIKE '%-nic none%'
      OR COALESCE(validation_cmd, '') LIKE '%-net none%'
      OR COALESCE(validation_result, '') LIKE '%-nic none%'
      OR COALESCE(notes, '') LIKE '%-nic none%'
      OR COALESCE(notes, '') LIKE '%-net none%'
    ) AS no_net_evidence_row,
    (
      COALESCE(validation_cmd, '') || ' ' ||
      COALESCE(validation_result, '') || ' ' ||
      COALESCE(notes, '') || ' ' ||
      COALESCE(files_changed, '')
    ) LIKE '%BookOfTruth%'
    OR (
      COALESCE(validation_cmd, '') || ' ' ||
      COALESCE(validation_result, '') || ' ' ||
      COALESCE(notes, '') || ' ' ||
      COALESCE(files_changed, '')
    ) LIKE '%bookoftruth%' AS bookoftruth_row
  FROM builder
)
SELECT
  agent,
  COUNT(*) AS rows,
  SUM(remote_row) AS remote_rows,
  SUM(strict_host_disabled) AS strict_host_disabled_rows,
  SUM(CASE WHEN remote_row AND strict_host_disabled THEN 1 ELSE 0 END) AS remote_strict_disabled_rows,
  ROUND(
    100.0 * SUM(CASE WHEN remote_row AND strict_host_disabled THEN 1 ELSE 0 END)
    / NULLIF(SUM(remote_row), 0),
    1
  ) AS pct_remote_strict_disabled,
  SUM(CASE WHEN remote_row AND scp_row THEN 1 ELSE 0 END) AS remote_scp_rows,
  SUM(CASE WHEN remote_row AND azure_ip_row THEN 1 ELSE 0 END) AS remote_azure_ip_rows,
  SUM(CASE WHEN remote_row AND host_key_pin_row THEN 1 ELSE 0 END) AS remote_host_key_pin_rows,
  SUM(CASE WHEN remote_row AND bookoftruth_row THEN 1 ELSE 0 END) AS remote_bookoftruth_rows,
  SUM(CASE WHEN remote_row AND qemu_row THEN 1 ELSE 0 END) AS remote_qemu_rows,
  SUM(CASE WHEN remote_row AND no_net_evidence_row THEN 1 ELSE 0 END) AS remote_no_net_evidence_rows
FROM classified
GROUP BY agent
ORDER BY agent;

SELECT
  substr(ts, 1, 10) AS day,
  COUNT(*) AS remote_rows,
  SUM(COALESCE(validation_cmd, '') LIKE '%StrictHostKeyChecking=no%') AS strict_disabled_rows,
  SUM(COALESCE(validation_cmd, '') LIKE '%scp %') AS scp_rows,
  SUM(COALESCE(validation_cmd, '') LIKE '%azureuser@52.157.85.234%') AS azure_ip_rows,
  SUM(
    (COALESCE(validation_cmd, '') || ' ' || COALESCE(validation_result, '') || ' ' || COALESCE(notes, '') || ' ' || COALESCE(files_changed, '')) LIKE '%BookOfTruth%'
    OR (COALESCE(validation_cmd, '') || ' ' || COALESCE(validation_result, '') || ' ' || COALESCE(notes, '') || ' ' || COALESCE(files_changed, '')) LIKE '%bookoftruth%'
  ) AS bookoftruth_rows
FROM iterations
WHERE agent = 'modernization'
  AND (
    COALESCE(validation_cmd, '') LIKE '%ssh %'
    OR COALESCE(validation_cmd, '') LIKE '%scp %'
    OR COALESCE(validation_cmd, '') LIKE '%azureuser@%'
    OR COALESCE(validation_cmd, '') LIKE '%52.157.85.234%'
  )
GROUP BY day
ORDER BY day;

SELECT
  COUNT(*) AS modernization_rows,
  SUM(COALESCE(validation_cmd, '') LIKE '%StrictHostKeyChecking=no%') AS strict_disabled_rows,
  SUM(
    COALESCE(validation_cmd, '') LIKE '%ssh -o StrictHostKeyChecking=no%'
    OR COALESCE(validation_cmd, '') LIKE '%scp -o StrictHostKeyChecking=no%'
  ) AS transport_strict_disabled_rows,
  SUM(COALESCE(validation_cmd, '') LIKE '%UserKnownHostsFile=/dev/null%') AS known_hosts_null_rows,
  SUM(COALESCE(validation_cmd, '') LIKE '%azureuser@52.157.85.234%') AS azure_ip_rows,
  SUM(
    COALESCE(validation_cmd, '') LIKE '%ssh-keyscan%'
    OR COALESCE(validation_cmd, '') LIKE '%known_hosts%'
  ) AS host_key_pin_rows
FROM iterations
WHERE agent = 'modernization';

SELECT
  id,
  ts,
  task_id,
  substr(files_changed, 1, 70) AS files_changed,
  substr(validation_cmd, 1, 140) AS validation_cmd,
  substr(validation_result, 1, 90) AS validation_result
FROM iterations
WHERE agent = 'modernization'
  AND COALESCE(validation_cmd, '') LIKE '%StrictHostKeyChecking=no%'
ORDER BY id
LIMIT 10;

SELECT
  id,
  ts,
  task_id,
  substr(files_changed, 1, 70) AS files_changed,
  substr(validation_cmd, 1, 140) AS validation_cmd,
  substr(validation_result, 1, 90) AS validation_result
FROM iterations
WHERE agent = 'modernization'
  AND COALESCE(validation_cmd, '') LIKE '%scp -o StrictHostKeyChecking=no%'
ORDER BY id
LIMIT 10;
