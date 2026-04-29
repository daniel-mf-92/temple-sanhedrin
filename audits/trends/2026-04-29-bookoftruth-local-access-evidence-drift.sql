-- Historical Book of Truth local-access evidence drift audit.
-- Read-only query pack used by:
-- audits/trends/2026-04-29-bookoftruth-local-access-evidence-drift.md

.headers on
.mode column

WITH text_rows AS (
  SELECT
    id,
    ts,
    agent,
    status,
    task_id,
    replace(replace(coalesce(validation_cmd, ''), char(10), ' '), char(13), ' ') AS validation_line,
    replace(replace(coalesce(notes, ''), char(10), ' '), char(13), ' ') AS notes_line,
    lower(
      coalesce(task_id, '') || ' ' ||
      coalesce(files_changed, '') || ' ' ||
      coalesce(validation_cmd, '') || ' ' ||
      coalesce(validation_result, '') || ' ' ||
      coalesce(error_msg, '') || ' ' ||
      coalesce(notes, '')
    ) AS body
  FROM iterations
)
SELECT
  agent,
  count(*) AS rows,
  sum(CASE WHEN body GLOB '*book*truth*' OR body GLOB '*bot_*' THEN 1 ELSE 0 END) AS bot_rows,
  sum(CASE WHEN body GLOB '*serial*' THEN 1 ELSE 0 END) AS serial_rows,
  sum(
    CASE WHEN
      body GLOB '*export*' OR body GLOB '*dump*' OR
      body GLOB '*copy*' OR body GLOB '*usb*' OR
      body GLOB '*remote*' OR body GLOB '*stream*' OR
      body GLOB '*proxy*' OR body GLOB '*forward*'
    THEN 1 ELSE 0 END
  ) AS access_term_rows,
  sum(
    CASE WHEN
      (body GLOB '*book*truth*' OR body GLOB '*bot_*') AND
      (
        body GLOB '*export*' OR body GLOB '*dump*' OR
        body GLOB '*copy*' OR body GLOB '*usb*' OR
        body GLOB '*remote*' OR body GLOB '*stream*' OR
        body GLOB '*proxy*' OR body GLOB '*forward*'
      )
    THEN 1 ELSE 0 END
  ) AS bot_access_rows,
  min(ts) AS first_ts,
  max(ts) AS last_ts
FROM text_rows
GROUP BY agent
ORDER BY agent;

WITH text_rows AS (
  SELECT
    id,
    ts,
    agent,
    status,
    task_id,
    lower(
      coalesce(task_id, '') || ' ' ||
      coalesce(files_changed, '') || ' ' ||
      coalesce(validation_cmd, '') || ' ' ||
      coalesce(validation_result, '') || ' ' ||
      coalesce(error_msg, '') || ' ' ||
      coalesce(notes, '')
    ) AS body
  FROM iterations
)
SELECT
  count(*) AS rows,
  sum(CASE WHEN body GLOB '*exported extern*' OR body GLOB '*extern export*' OR body GLOB '*export in kernel/kexts*' OR body GLOB '*exported api*' THEN 1 ELSE 0 END) AS extern_export_rows,
  sum(CASE WHEN body GLOB '*remote*' THEN 1 ELSE 0 END) AS remote_rows,
  sum(CASE WHEN body GLOB '*usb*' THEN 1 ELSE 0 END) AS usb_rows,
  sum(CASE WHEN body GLOB '*stream*' OR body GLOB '*proxy*' OR body GLOB '*forward*' THEN 1 ELSE 0 END) AS forwarding_rows
FROM text_rows
WHERE agent = 'modernization'
  AND (body GLOB '*book*truth*' OR body GLOB '*bot_*')
  AND (
    body GLOB '*export*' OR body GLOB '*dump*' OR
    body GLOB '*copy*' OR body GLOB '*usb*' OR
    body GLOB '*remote*' OR body GLOB '*stream*' OR
    body GLOB '*proxy*' OR body GLOB '*forward*'
  );

WITH text_rows AS (
  SELECT
    id,
    ts,
    agent,
    status,
    task_id,
    replace(replace(coalesce(validation_cmd, ''), char(10), ' '), char(13), ' ') AS validation_line,
    replace(replace(coalesce(notes, ''), char(10), ' '), char(13), ' ') AS notes_line,
    lower(
      coalesce(task_id, '') || ' ' ||
      coalesce(files_changed, '') || ' ' ||
      coalesce(validation_cmd, '') || ' ' ||
      coalesce(validation_result, '') || ' ' ||
      coalesce(error_msg, '') || ' ' ||
      coalesce(notes, '')
    ) AS body
  FROM iterations
)
SELECT
  id,
  ts,
  status,
  task_id,
  substr(validation_line, 1, 120) AS validation_sample,
  substr(notes_line, 1, 170) AS notes_sample
FROM text_rows
WHERE agent = 'modernization'
  AND (body GLOB '*book*truth*' OR body GLOB '*bot_*')
  AND (body GLOB '*remote*' OR body GLOB '*usb*' OR body GLOB '*stream*' OR body GLOB '*proxy*' OR body GLOB '*forward*')
ORDER BY ts
LIMIT 40;

WITH text_rows AS (
  SELECT
    substr(ts, 1, 10) AS day,
    agent,
    lower(
      coalesce(task_id, '') || ' ' ||
      coalesce(files_changed, '') || ' ' ||
      coalesce(validation_cmd, '') || ' ' ||
      coalesce(validation_result, '') || ' ' ||
      coalesce(error_msg, '') || ' ' ||
      coalesce(notes, '')
    ) AS body
  FROM iterations
)
SELECT
  day,
  agent,
  count(*) AS bot_access_rows,
  sum(CASE WHEN body GLOB '*serial*' THEN 1 ELSE 0 END) AS serial_mentions,
  sum(CASE WHEN body GLOB '*remote*' THEN 1 ELSE 0 END) AS remote_mentions,
  sum(CASE WHEN body GLOB '*export*' OR body GLOB '*dump*' THEN 1 ELSE 0 END) AS export_dump_mentions
FROM text_rows
WHERE (body GLOB '*book*truth*' OR body GLOB '*bot_*')
  AND (
    body GLOB '*export*' OR body GLOB '*dump*' OR
    body GLOB '*copy*' OR body GLOB '*usb*' OR
    body GLOB '*remote*' OR body GLOB '*stream*' OR
    body GLOB '*proxy*' OR body GLOB '*forward*'
  )
GROUP BY day, agent
ORDER BY day, agent;
