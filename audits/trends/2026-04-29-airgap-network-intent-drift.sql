-- Historical air-gap and network-intent drift audit for temple-central.db.
-- Read-only query pack used by:
-- audits/trends/2026-04-29-airgap-network-intent-drift.md

.headers on
.mode column

WITH text_rows AS (
  SELECT
    agent,
    status,
    ts,
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
),
builder_rows AS (
  SELECT * FROM text_rows WHERE agent IN ('modernization', 'inference')
)
SELECT
  agent,
  count(*) AS builder_rows,
  sum(
    CASE WHEN
      body GLOB '*network*' OR body GLOB '*socket*' OR
      body GLOB '*tcp*' OR body GLOB '*udp*' OR
      body GLOB '*http*' OR body GLOB '*dns*' OR
      body GLOB '*dhcp*'
    THEN 1 ELSE 0 END
  ) AS network_term_rows,
  sum(
    CASE WHEN
      body GLOB '*air-gap*' OR body GLOB '*no network*' OR
      body GLOB '*no-network*' OR body GLOB '*-nic none*' OR
      body GLOB '*-net none*'
    THEN 1 ELSE 0 END
  ) AS no_network_evidence_rows,
  sum(CASE WHEN body GLOB '*ws8*' THEN 1 ELSE 0 END) AS ws8_rows,
  min(ts) AS first_ts,
  max(ts) AS last_ts
FROM builder_rows
GROUP BY agent
ORDER BY agent;

WITH text_rows AS (
  SELECT
    agent,
    status,
    ts,
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
  status,
  count(*) AS ws8_rows,
  min(ts) AS first_ts,
  max(ts) AS last_ts
FROM text_rows
WHERE body GLOB '*ws8*'
GROUP BY agent, status
ORDER BY agent, status;

WITH text_rows AS (
  SELECT
    id,
    ts,
    agent,
    status,
    task_id,
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
  agent,
  status,
  task_id,
  substr(notes_line, 1, 220) AS notes_sample
FROM text_rows
WHERE agent IN ('modernization', 'inference')
  AND (
    body GLOB '*network*' OR body GLOB '*socket*' OR
    body GLOB '*tcp*' OR body GLOB '*udp*' OR
    body GLOB '*http*' OR body GLOB '*dns*' OR
    body GLOB '*dhcp*'
  )
ORDER BY ts;

SELECT
  topic,
  count(*) AS rows,
  min(ts) AS first_ts,
  max(ts) AS last_ts
FROM research
WHERE lower(
    coalesce(topic, '') || ' ' ||
    coalesce(trigger_task, '') || ' ' ||
    coalesce(findings, '') || ' ' ||
    coalesce(references_urls, '')
  ) GLOB '*network*'
  OR lower(
    coalesce(topic, '') || ' ' ||
    coalesce(trigger_task, '') || ' ' ||
    coalesce(findings, '') || ' ' ||
    coalesce(references_urls, '')
  ) GLOB '*air-gap*'
  OR lower(
    coalesce(topic, '') || ' ' ||
    coalesce(trigger_task, '') || ' ' ||
    coalesce(findings, '') || ' ' ||
    coalesce(references_urls, '')
  ) GLOB '*qemu*'
GROUP BY topic
ORDER BY rows DESC, topic;
