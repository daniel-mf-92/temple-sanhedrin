-- Historical QEMU air-gap command evidence drift audit.
-- Source DB: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Run with:
--   sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-01-qemu-airgap-command-evidence-drift.sql

.headers on
.mode column

WITH rows AS (
  SELECT
    id,
    ts,
    substr(ts, 1, 10) AS day,
    agent,
    task_id,
    status,
    files_changed,
    validation_cmd,
    validation_result,
    notes,
    lower(coalesce(task_id, '') || ' ' || coalesce(files_changed, '') || ' ' ||
          coalesce(validation_cmd, '') || ' ' || coalesce(validation_result, '') ||
          ' ' || coalesce(error_msg, '') || ' ' || coalesce(notes, '')) AS hay,
    lower(coalesce(validation_cmd, '')) AS cmd,
    lower(coalesce(files_changed, '')) AS files
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
), flags AS (
  SELECT
    *,
    cmd LIKE '%qemu%' AS cmd_qemu,
    (cmd LIKE '%-nic none%' OR cmd LIKE '%-net none%') AS cmd_literal_disable,
    (hay LIKE '%-nic none%' OR hay LIKE '%-net none%') AS row_literal_disable,
    (hay LIKE '%air-gap%' OR hay LIKE '%airgap%' OR hay LIKE '%air-gapped%' OR
     hay LIKE '%no guest networking%' OR hay LIKE '%no-network%' OR
     hay LIKE '%no networking%') AS row_airgap_language,
    (files LIKE '%kernel/%' OR files LIKE '%adam/%' OR files LIKE '%apps/%' OR
     files LIKE '%compiler/%' OR files LIKE '%0000boot/%' OR files LIKE '%src/%') AS touches_core,
    (cmd LIKE '%ssh %' OR cmd LIKE '%ssh -%') AS cmd_mentions_ssh,
    (hay LIKE '%socket%' OR hay LIKE '%tcp%' OR hay LIKE '%udp%' OR
     hay LIKE '%dns%' OR hay LIKE '%dhcp%' OR hay LIKE '%http%' OR
     hay LIKE '%tls%') AS protocol_terms
  FROM rows
)
SELECT
  'overall_qemu_airgap_evidence' AS section,
  agent,
  count(*) AS rows,
  sum(cmd_qemu) AS qemu_cmd_rows,
  sum(cmd_qemu AND cmd_literal_disable) AS qemu_cmd_literal_disable,
  sum(cmd_qemu AND NOT cmd_literal_disable) AS qemu_cmd_missing_literal_disable,
  sum(cmd_qemu AND NOT cmd_literal_disable AND row_literal_disable) AS missing_cmd_but_row_has_disable,
  sum(cmd_qemu AND NOT cmd_literal_disable AND NOT row_literal_disable AND row_airgap_language) AS missing_cmd_but_airgap_language,
  sum(cmd_qemu AND NOT cmd_literal_disable AND NOT row_literal_disable AND NOT row_airgap_language) AS qemu_no_disable_or_airgap_text,
  sum(cmd_qemu AND NOT cmd_literal_disable AND NOT row_literal_disable AND NOT row_airgap_language AND touches_core) AS qemu_no_evidence_touching_core,
  sum(cmd_qemu AND NOT cmd_literal_disable AND NOT row_literal_disable AND NOT row_airgap_language AND cmd_mentions_ssh) AS qemu_no_evidence_with_ssh,
  sum(protocol_terms) AS protocol_term_rows
FROM flags
GROUP BY agent
ORDER BY agent;

WITH rows AS (
  SELECT
    id,
    ts,
    substr(ts, 1, 10) AS day,
    agent,
    task_id,
    status,
    files_changed,
    validation_cmd,
    validation_result,
    notes,
    lower(coalesce(task_id, '') || ' ' || coalesce(files_changed, '') || ' ' ||
          coalesce(validation_cmd, '') || ' ' || coalesce(validation_result, '') ||
          ' ' || coalesce(error_msg, '') || ' ' || coalesce(notes, '')) AS hay,
    lower(coalesce(validation_cmd, '')) AS cmd,
    lower(coalesce(files_changed, '')) AS files
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
), flags AS (
  SELECT
    *,
    cmd LIKE '%qemu%' AS cmd_qemu,
    (cmd LIKE '%-nic none%' OR cmd LIKE '%-net none%') AS cmd_literal_disable,
    (hay LIKE '%-nic none%' OR hay LIKE '%-net none%') AS row_literal_disable,
    (hay LIKE '%air-gap%' OR hay LIKE '%airgap%' OR hay LIKE '%air-gapped%' OR
     hay LIKE '%no guest networking%' OR hay LIKE '%no-network%' OR
     hay LIKE '%no networking%') AS row_airgap_language
  FROM rows
)
SELECT
  'daily_qemu_airgap_evidence' AS section,
  day,
  agent,
  sum(cmd_qemu) AS qemu_cmd_rows,
  sum(cmd_qemu AND cmd_literal_disable) AS literal_disable_in_cmd,
  sum(cmd_qemu AND NOT cmd_literal_disable AND row_literal_disable) AS row_disable_only,
  sum(cmd_qemu AND NOT cmd_literal_disable AND NOT row_literal_disable AND row_airgap_language) AS prose_airgap_only,
  sum(cmd_qemu AND NOT cmd_literal_disable AND NOT row_literal_disable AND NOT row_airgap_language) AS no_disable_evidence
FROM flags
GROUP BY day, agent
HAVING qemu_cmd_rows > 0
ORDER BY day, agent;

WITH rows AS (
  SELECT
    id,
    ts,
    agent,
    task_id,
    status,
    files_changed,
    validation_cmd,
    validation_result,
    notes,
    lower(coalesce(task_id, '') || ' ' || coalesce(files_changed, '') || ' ' ||
          coalesce(validation_cmd, '') || ' ' || coalesce(validation_result, '') ||
          ' ' || coalesce(error_msg, '') || ' ' || coalesce(notes, '')) AS hay,
    lower(coalesce(validation_cmd, '')) AS cmd,
    lower(coalesce(files_changed, '')) AS files
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
), flags AS (
  SELECT
    *,
    cmd LIKE '%qemu%' AS cmd_qemu,
    (cmd LIKE '%-nic none%' OR cmd LIKE '%-net none%') AS cmd_literal_disable,
    (hay LIKE '%-nic none%' OR hay LIKE '%-net none%') AS row_literal_disable,
    (hay LIKE '%air-gap%' OR hay LIKE '%airgap%' OR hay LIKE '%air-gapped%' OR
     hay LIKE '%no guest networking%' OR hay LIKE '%no-network%' OR
     hay LIKE '%no networking%') AS row_airgap_language,
    (files LIKE '%kernel/%' OR files LIKE '%adam/%' OR files LIKE '%apps/%' OR
     files LIKE '%compiler/%' OR files LIKE '%0000boot/%' OR files LIKE '%src/%') AS touches_core
  FROM rows
)
SELECT
  'latest_qemu_rows_without_airgap_evidence' AS section,
  id,
  ts,
  agent,
  task_id,
  status,
  touches_core,
  substr(files_changed, 1, 100) AS files_changed,
  substr(validation_cmd, 1, 180) AS validation_cmd,
  substr(validation_result, 1, 80) AS validation_result,
  substr(notes, 1, 140) AS notes
FROM flags
WHERE cmd_qemu
  AND NOT cmd_literal_disable
  AND NOT row_literal_disable
  AND NOT row_airgap_language
ORDER BY id DESC
LIMIT 20;
