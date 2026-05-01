-- Historical trend audit: Book of Truth signal saturation drift.
-- Scope: read-only evidence-quality queries from modernization iteration rows.
-- Verification:
--   sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-01-bookoftruth-signal-saturation-drift.sql

.headers on
.mode column

WITH modernization AS (
  SELECT
    id,
    ts,
    task_id,
    files_changed,
    validation_cmd,
    validation_result,
    notes,
    lower(
      coalesce(notes, '') || ' ' ||
      coalesce(files_changed, '') || ' ' ||
      coalesce(validation_cmd, '') || ' ' ||
      coalesce(validation_result, '')
    ) AS body
  FROM iterations
  WHERE agent = 'modernization'
),
flags AS (
  SELECT
    *,
    (body LIKE '%bookoftruth%' OR body LIKE '%book of truth%') AS bot_signal,
    (body LIKE '%serial%' OR body LIKE '%uart%' OR body LIKE '%0x3f8%') AS serial_signal,
    (body LIKE '%hash%' OR body LIKE '%seal%') AS immutability_signal,
    (body LIKE '%failstop%' OR body LIKE '%hlt%' OR body LIKE '%halt%') AS failstop_signal,
    (body LIKE '%readonly%' OR body LIKE '%readonly=on%') AS readonly_signal,
    (
      body LIKE '%-nic none%' OR
      body LIKE '%-net none%' OR
      body LIKE '%air-gap%' OR
      body LIKE '%airgapped%' OR
      body LIKE '%air-gapped%'
    ) AS airgap_signal
  FROM modernization
)
SELECT
  'overall_law_signal_counts' AS section,
  count(*) AS modernization_rows,
  sum(bot_signal) AS bookoftruth_rows,
  sum(serial_signal) AS serial_or_uart_rows,
  sum(immutability_signal) AS hash_or_seal_rows,
  sum(failstop_signal) AS failstop_or_halt_rows,
  sum(readonly_signal) AS readonly_rows,
  sum(airgap_signal) AS airgap_rows,
  sum(
    bot_signal AND NOT (
      serial_signal OR immutability_signal OR failstop_signal OR readonly_signal OR airgap_signal
    )
  ) AS bot_without_specific_law_signal,
  sum(
    bot_signal AND
    (serial_signal + immutability_signal + failstop_signal + readonly_signal + airgap_signal) >= 2
  ) AS bot_multi_law_signal
FROM flags;

WITH modernization AS (
  SELECT
    substr(ts, 1, 10) AS day,
    lower(
      coalesce(notes, '') || ' ' ||
      coalesce(files_changed, '') || ' ' ||
      coalesce(validation_cmd, '') || ' ' ||
      coalesce(validation_result, '')
    ) AS body
  FROM iterations
  WHERE agent = 'modernization'
),
flags AS (
  SELECT
    day,
    (body LIKE '%bookoftruth%' OR body LIKE '%book of truth%') AS bot_signal,
    (body LIKE '%serial%' OR body LIKE '%uart%' OR body LIKE '%0x3f8%') AS serial_signal,
    (body LIKE '%hash%' OR body LIKE '%seal%') AS immutability_signal,
    (body LIKE '%failstop%' OR body LIKE '%hlt%' OR body LIKE '%halt%') AS failstop_signal,
    (body LIKE '%readonly%' OR body LIKE '%readonly=on%') AS readonly_signal,
    (
      body LIKE '%-nic none%' OR
      body LIKE '%-net none%' OR
      body LIKE '%air-gap%' OR
      body LIKE '%airgapped%' OR
      body LIKE '%air-gapped%'
    ) AS airgap_signal
  FROM modernization
)
SELECT
  'daily_law_signal_counts' AS section,
  day,
  count(*) AS rows,
  sum(bot_signal) AS bookoftruth_rows,
  sum(serial_signal) AS serial_or_uart_rows,
  sum(immutability_signal) AS hash_or_seal_rows,
  sum(failstop_signal) AS failstop_or_halt_rows,
  sum(readonly_signal) AS readonly_rows,
  sum(airgap_signal) AS airgap_rows
FROM flags
GROUP BY day
ORDER BY day;

WITH modernization AS (
  SELECT
    id,
    ts,
    task_id,
    files_changed,
    validation_cmd,
    validation_result,
    lower(
      coalesce(notes, '') || ' ' ||
      coalesce(files_changed, '') || ' ' ||
      coalesce(validation_cmd, '') || ' ' ||
      coalesce(validation_result, '')
    ) AS body
  FROM iterations
  WHERE agent = 'modernization'
),
flags AS (
  SELECT
    *,
    (body LIKE '%bookoftruth%' OR body LIKE '%book of truth%') AS bot_signal,
    (body LIKE '%serial%' OR body LIKE '%uart%' OR body LIKE '%0x3f8%') AS serial_signal,
    (body LIKE '%hash%' OR body LIKE '%seal%') AS immutability_signal,
    (body LIKE '%failstop%' OR body LIKE '%hlt%' OR body LIKE '%halt%') AS failstop_signal,
    (body LIKE '%readonly%' OR body LIKE '%readonly=on%') AS readonly_signal,
    (
      body LIKE '%-nic none%' OR
      body LIKE '%-net none%' OR
      body LIKE '%air-gap%' OR
      body LIKE '%airgapped%' OR
      body LIKE '%air-gapped%'
    ) AS airgap_signal
  FROM modernization
)
SELECT
  'generic_bookoftruth_rows' AS section,
  count(*) AS bot_rows,
  sum(validation_result = 'exit 0') AS bot_generic_exit0_rows,
  sum(validation_cmd LIKE '%qemu%') AS bot_qemu_cmd_rows,
  sum(validation_cmd LIKE '%qemu%' AND validation_result = 'exit 0') AS bot_qemu_generic_exit0_rows
FROM flags
WHERE bot_signal;

WITH modernization AS (
  SELECT
    id,
    ts,
    task_id,
    files_changed,
    validation_cmd,
    validation_result,
    lower(
      coalesce(notes, '') || ' ' ||
      coalesce(files_changed, '') || ' ' ||
      coalesce(validation_cmd, '') || ' ' ||
      coalesce(validation_result, '')
    ) AS body
  FROM iterations
  WHERE agent = 'modernization'
),
flags AS (
  SELECT
    *,
    (body LIKE '%bookoftruth%' OR body LIKE '%book of truth%') AS bot_signal,
    (body LIKE '%serial%' OR body LIKE '%uart%' OR body LIKE '%0x3f8%') AS serial_signal,
    (body LIKE '%hash%' OR body LIKE '%seal%') AS immutability_signal,
    (body LIKE '%failstop%' OR body LIKE '%hlt%' OR body LIKE '%halt%') AS failstop_signal,
    (body LIKE '%readonly%' OR body LIKE '%readonly=on%') AS readonly_signal,
    (
      body LIKE '%-nic none%' OR
      body LIKE '%-net none%' OR
      body LIKE '%air-gap%' OR
      body LIKE '%airgapped%' OR
      body LIKE '%air-gapped%'
    ) AS airgap_signal
  FROM modernization
)
SELECT
  'sample_bot_without_specific_signal' AS section,
  id,
  ts,
  task_id,
  substr(files_changed, 1, 120) AS files_prefix,
  substr(validation_cmd, 1, 160) AS validation_cmd_prefix,
  validation_result
FROM flags
WHERE bot_signal
  AND NOT (serial_signal OR immutability_signal OR failstop_signal OR readonly_signal OR airgap_signal)
ORDER BY id DESC
LIMIT 15;
