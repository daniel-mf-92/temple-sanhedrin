-- Historical host-remote validation dependency drift audit.
-- Source: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- This query is read-only and does not execute any SSH, QEMU, VM, or network command.

.headers on
.mode column

WITH builder AS (
  SELECT
    *,
    lower(
      coalesce(validation_cmd, '') || ' ' ||
      coalesce(validation_result, '') || ' ' ||
      coalesce(notes, '') || ' ' ||
      coalesce(error_msg, '')
    ) AS body
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
),
flags AS (
  SELECT
    agent,
    date(ts) AS day,
    task_id,
    ts,
    status,
    files_changed,
    validation_cmd,
    validation_result,
    lines_added,
    lines_removed,
    CASE WHEN body LIKE '%ssh %' THEN 1 ELSE 0 END AS has_ssh,
    CASE WHEN body LIKE '%azureuser@%' OR body LIKE '%52.157.%' THEN 1 ELSE 0 END AS has_azure,
    CASE WHEN body LIKE '%scp %' THEN 1 ELSE 0 END AS has_scp,
    CASE WHEN body LIKE '%curl %' OR body LIKE '%wget %' OR body LIKE '%http%' THEN 1 ELSE 0 END AS has_http,
    CASE
      WHEN body LIKE '%operation not permitted%'
        OR body LIKE '%could not resolve hostname%'
        OR body LIKE '%auth timeout%'
        OR body LIKE '%connection timed out%'
      THEN 1 ELSE 0
    END AS remote_blocked
  FROM builder
)
SELECT
  'agent_totals' AS section,
  agent,
  NULL AS day,
  count(*) AS rows,
  sum(has_ssh) AS ssh_rows,
  sum(has_azure) AS azure_rows,
  sum(has_scp) AS scp_rows,
  sum(has_http) AS http_rows,
  sum(remote_blocked) AS remote_blocked_rows,
  round(100.0 * sum(has_ssh) / count(*), 2) AS ssh_pct
FROM flags
GROUP BY agent
UNION ALL
SELECT
  'modernization_daily_remote' AS section,
  agent,
  day,
  count(*) AS rows,
  sum(has_ssh) AS ssh_rows,
  sum(has_azure) AS azure_rows,
  sum(has_scp) AS scp_rows,
  sum(has_http) AS http_rows,
  sum(remote_blocked) AS remote_blocked_rows,
  round(100.0 * sum(has_ssh) / count(*), 2) AS ssh_pct
FROM flags
WHERE agent = 'modernization'
GROUP BY agent, day
HAVING ssh_rows > 0 OR azure_rows > 0 OR scp_rows > 0 OR http_rows > 0 OR remote_blocked_rows > 0
ORDER BY section, agent, day;

WITH builder AS (
  SELECT
    *,
    lower(
      coalesce(validation_cmd, '') || ' ' ||
      coalesce(validation_result, '') || ' ' ||
      coalesce(notes, '') || ' ' ||
      coalesce(error_msg, '')
    ) AS body
  FROM iterations
  WHERE agent = 'modernization'
)
SELECT
  id,
  ts,
  task_id,
  substr(validation_cmd, 1, 160) AS validation_cmd_prefix,
  validation_result,
  substr(notes, 1, 100) AS notes_prefix
FROM builder
WHERE body LIKE '%ssh %'
   OR body LIKE '%azureuser@%'
   OR body LIKE '%52.157.%'
   OR body LIKE '%scp %'
ORDER BY ts
LIMIT 12;

WITH builder AS (
  SELECT
    *,
    lower(
      coalesce(validation_cmd, '') || ' ' ||
      coalesce(validation_result, '') || ' ' ||
      coalesce(notes, '') || ' ' ||
      coalesce(error_msg, '')
    ) AS body
  FROM iterations
  WHERE agent = 'modernization'
)
SELECT
  id,
  ts,
  task_id,
  substr(validation_cmd, 1, 160) AS validation_cmd_prefix,
  validation_result,
  substr(notes, 1, 100) AS notes_prefix
FROM builder
WHERE body LIKE '%ssh %'
   OR body LIKE '%azureuser@%'
   OR body LIKE '%52.157.%'
   OR body LIKE '%scp %'
ORDER BY ts DESC
LIMIT 12;
