-- Historical timestamp integrity drift audit for temple-central.db.
-- Read-only query pack used by:
-- audits/trends/2026-04-29-temple-central-timestamp-integrity-drift.md

.headers on
.mode column

SELECT
  agent,
  status,
  count(*) AS rows,
  min(id) AS first_id,
  max(id) AS last_id,
  min(ts) AS min_ts,
  max(ts) AS max_ts
FROM iterations
WHERE ts NOT GLOB '????-??-??T??:??:??*'
GROUP BY agent, status
ORDER BY rows DESC;

SELECT
  CASE
    WHEN ts GLOB '????-??-??T??:??:??*' THEN 'iso_t_separator'
    WHEN ts GLOB '????-??-?? ??:??:??*' THEN 'space_separator'
    WHEN ts GLOB '??????????' AND ts NOT GLOB '*[^0-9]*' THEN 'unix_epoch_like'
    ELSE 'other'
  END AS ts_shape,
  agent,
  status,
  count(*) AS rows,
  min(id) AS first_id,
  max(id) AS last_id,
  min(ts) AS min_ts,
  max(ts) AS max_ts
FROM iterations
GROUP BY ts_shape, agent, status
ORDER BY ts_shape, agent, status;

SELECT
  id,
  ts,
  agent,
  status,
  task_id,
  substr(replace(replace(coalesce(notes, ''), char(10), ' '), char(13), ' '), 1, 140) AS notes_sample
FROM iterations
WHERE ts NOT GLOB '????-??-??T??:??:??*'
ORDER BY id;

SELECT
  agent,
  task_id,
  count(*) AS rows,
  sum(CASE WHEN ts GLOB '????-??-??T??:??:??*' THEN 1 ELSE 0 END) AS iso_rows,
  sum(CASE WHEN ts GLOB '????-??-?? ??:??:??*' THEN 1 ELSE 0 END) AS space_rows,
  sum(CASE WHEN ts GLOB '??????????' AND ts NOT GLOB '*[^0-9]*' THEN 1 ELSE 0 END) AS epoch_rows
FROM iterations
GROUP BY agent, task_id
HAVING space_rows > 0 OR epoch_rows > 0
ORDER BY rows DESC;

WITH ordered AS (
  SELECT
    id,
    ts,
    agent,
    task_id,
    lag(ts) OVER (ORDER BY id) AS prev_ts
  FROM iterations
  WHERE ts GLOB '????-??-??T??:??:??*'
)
SELECT
  count(*) AS backwards_iso_rows,
  min(id) AS first_id,
  max(id) AS last_id
FROM ordered
WHERE prev_ts IS NOT NULL
  AND ts < prev_ts;

SELECT
  count(*) AS total_rows,
  sum(CASE WHEN duration_sec IS NULL THEN 1 ELSE 0 END) AS null_duration_rows,
  sum(CASE WHEN duration_sec < 0 THEN 1 ELSE 0 END) AS negative_duration_rows,
  sum(CASE WHEN duration_sec > 1800 THEN 1 ELSE 0 END) AS over_30m_rows,
  max(duration_sec) AS max_duration_sec
FROM iterations;

SELECT
  count(*) AS research_rows,
  sum(CASE WHEN ts GLOB '????-??-??T??:??:??*' THEN 1 ELSE 0 END) AS iso_rows,
  sum(CASE WHEN ts NOT GLOB '????-??-??T??:??:??*' THEN 1 ELSE 0 END) AS non_iso_rows,
  min(ts) AS first_ts,
  max(ts) AS last_ts
FROM research;
