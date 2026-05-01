-- Historical drift audit: Sanhedrin CI blocker deduplication and Law 7 escalation evidence.
-- Source DB: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Read-only usage:
--   sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-02-ci-blocker-dedup-law7-drift.sql

.print '== ci task rows grouped by repeat key =='
WITH ci AS (
  SELECT
    id,
    ts,
    task_id,
    status,
    notes,
    CASE
      WHEN notes LIKE '%24308638070%' OR task_id LIKE '%24308638070%' THEN 'run_24308638070'
      WHEN lower(notes) LIKE '%unknown step%' THEN 'unknown_step'
      WHEN lower(notes) LIKE '%api.github.com%' THEN 'github_api_blocked'
      ELSE 'other_ci'
    END AS repeat_key
  FROM iterations
  WHERE agent = 'sanhedrin'
    AND task_id LIKE 'CI%'
)
SELECT
  repeat_key,
  count(*) AS rows,
  min(ts) AS first_ts,
  max(ts) AS last_ts,
  sum(status = 'fail') AS fail_rows,
  sum(status = 'skip') AS skip_rows,
  sum(status = 'pass') AS pass_rows
FROM ci
GROUP BY repeat_key
ORDER BY rows DESC;

.print ''
.print '== long consecutive ci repeat-key streaks =='
WITH ordered AS (
  SELECT
    id,
    ts,
    task_id,
    status,
    notes,
    CASE
      WHEN notes LIKE '%24308638070%' OR task_id LIKE '%24308638070%' THEN 'run_24308638070'
      WHEN lower(notes) LIKE '%unknown step%' THEN 'unknown_step'
      WHEN lower(notes) LIKE '%api.github.com%' THEN 'github_api_blocked'
      ELSE 'other_ci'
    END AS repeat_key,
    row_number() OVER (ORDER BY ts, id) AS rn
  FROM iterations
  WHERE agent = 'sanhedrin'
    AND task_id LIKE 'CI%'
),
streaks AS (
  SELECT
    *,
    rn - row_number() OVER (PARTITION BY repeat_key ORDER BY ts, id) AS grp
  FROM ordered
)
SELECT
  repeat_key,
  count(*) AS streak_len,
  min(ts) AS start_ts,
  max(ts) AS end_ts,
  min(task_id) AS min_task_id,
  max(task_id) AS max_task_id
FROM streaks
GROUP BY repeat_key, grp
HAVING count(*) >= 3
ORDER BY streak_len DESC, start_ts
LIMIT 12;

.print ''
.print '== repeated run 24308638070 by day =='
SELECT
  date(ts) AS day,
  count(*) AS rows,
  sum(status = 'pass') AS pass_rows,
  sum(status = 'skip') AS skip_rows,
  sum(status = 'fail') AS fail_rows
FROM iterations
WHERE agent = 'sanhedrin'
  AND task_id LIKE 'CI%'
  AND (notes LIKE '%24308638070%' OR task_id LIKE '%24308638070%')
GROUP BY date(ts)
ORDER BY day;

.print ''
.print '== ci rows whose payload mentions failure =='
SELECT
  status,
  count(*) AS rows
FROM iterations
WHERE agent = 'sanhedrin'
  AND task_id LIKE 'CI%'
  AND (lower(notes) LIKE '%failed%' OR lower(notes) LIKE '%failure%')
GROUP BY status
ORDER BY status;

.print ''
.print '== ci fail rows missing structured error evidence =='
SELECT
  count(*) AS ci_fail_rows,
  sum(error_msg IS NULL OR trim(error_msg) = '') AS null_error_msg,
  sum(validation_result IS NULL OR trim(validation_result) = '') AS null_validation_result,
  sum(validation_cmd IS NULL OR trim(validation_cmd) = '') AS null_validation_cmd
FROM iterations
WHERE agent = 'sanhedrin'
  AND task_id LIKE 'CI%'
  AND status = 'fail';

.print ''
.print '== sample repeated run rows =='
SELECT
  ts,
  task_id,
  status,
  substr(notes, 1, 140) AS notes
FROM iterations
WHERE agent = 'sanhedrin'
  AND task_id LIKE 'CI%'
  AND (notes LIKE '%24308638070%' OR lower(notes) LIKE '%unknown step%')
ORDER BY ts
LIMIT 30;
