-- Historical drift audit: unchecked queue-depth and builder-side queue padding signals.
-- Source DB: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Read-only usage:
--   sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-02-unchecked-queue-depth-padding-drift.sql

.print '== unchecked queue-depth notes by agent/status =='
SELECT
  agent,
  status,
  count(*) AS rows,
  min(ts) AS first_ts,
  max(ts) AS last_ts
FROM iterations
WHERE lower(coalesce(notes, '')) LIKE '%unchecked%'
GROUP BY agent, status
ORDER BY rows DESC, agent, status;

.print ''
.print '== queue-depth note coverage by agent =='
SELECT
  agent,
  count(*) AS all_rows,
  sum(lower(coalesce(notes, '')) LIKE '%queue depth%') AS queue_depth_rows,
  sum(lower(coalesce(notes, '')) LIKE '%unchecked%') AS unchecked_rows,
  sum(lower(coalesce(notes, '')) LIKE '%unchecked%') * 100.0 / count(*) AS unchecked_pct
FROM iterations
GROUP BY agent
ORDER BY unchecked_rows DESC, agent;

.print ''
.print '== queue-padding language in iteration notes =='
SELECT
  agent,
  count(*) AS rows,
  sum(lower(coalesce(notes, '')) LIKE '%appended%') AS appended_rows,
  sum(lower(coalesce(notes, '')) LIKE '%topped up%') AS topped_up_rows,
  sum(lower(coalesce(notes, '')) LIKE '%refill%') AS refill_rows,
  sum(lower(coalesce(notes, '')) LIKE '%maintained%') AS maintained_rows,
  min(ts) AS first_ts,
  max(ts) AS last_ts
FROM iterations
WHERE lower(coalesce(notes, '')) LIKE '%unchecked%'
GROUP BY agent
ORDER BY rows DESC, agent;

.print ''
.print '== explicit append/top-up/refill notes that also mention queue or task ids =='
SELECT
  agent,
  count(*) AS append_or_refill_rows,
  min(ts) AS first_ts,
  max(ts) AS last_ts
FROM iterations
WHERE (
    lower(coalesce(notes, '')) LIKE '%append%'
    OR lower(coalesce(notes, '')) LIKE '%topped up%'
    OR lower(coalesce(notes, '')) LIKE '%refill%'
  )
  AND (
    lower(coalesce(notes, '')) LIKE '%queue%'
    OR lower(coalesce(notes, '')) LIKE '%cq-%'
    OR lower(coalesce(notes, '')) LIKE '%iq-%'
  )
GROUP BY agent
ORDER BY append_or_refill_rows DESC, agent;

.print ''
.print '== pass rows with unchecked or queue-padding language =='
SELECT
  agent,
  status,
  count(*) AS rows
FROM iterations
WHERE status = 'pass'
  AND (
    lower(coalesce(notes, '')) LIKE '%unchecked%'
    OR lower(coalesce(notes, '')) LIKE '%append%'
    OR lower(coalesce(notes, '')) LIKE '%topped up%'
    OR lower(coalesce(notes, '')) LIKE '%refill%'
  )
GROUP BY agent, status
ORDER BY rows DESC, agent;

.print ''
.print '== sample builder queue-padding rows =='
SELECT
  ts,
  agent,
  task_id,
  status,
  substr(notes, 1, 180) AS notes
FROM iterations
WHERE agent IN ('modernization', 'inference')
  AND (
    lower(coalesce(notes, '')) LIKE '%unchecked%'
    OR lower(coalesce(notes, '')) LIKE '%append%'
    OR lower(coalesce(notes, '')) LIKE '%topped up%'
    OR lower(coalesce(notes, '')) LIKE '%refill%'
  )
ORDER BY ts DESC
LIMIT 40;
