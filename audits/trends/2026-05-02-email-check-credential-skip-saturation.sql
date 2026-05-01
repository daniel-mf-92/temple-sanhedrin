-- Historical drift audit: Sanhedrin email-check credential skip saturation.
-- Source DB: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Read-only usage:
--   sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-02-email-check-credential-skip-saturation.sql

.print '== sanhedrin email-check share =='
SELECT
  count(*) AS total_sanhedrin,
  sum(task_id LIKE 'EMAIL%') AS email_rows,
  round(100.0 * sum(task_id LIKE 'EMAIL%') / count(*), 1) AS email_pct,
  sum(task_id LIKE 'EMAIL%' AND status = 'skip') AS email_skip_rows
FROM iterations
WHERE agent = 'sanhedrin';

.print ''
.print '== email-check normalized error keys =='
WITH email AS (
  SELECT
    id,
    ts,
    task_id,
    status,
    notes,
    CASE
      WHEN lower(notes) LIKE '%marta_google_client_id%'
        OR lower(notes) LIKE '%marta_google_client_secret%'
        THEN 'missing_marta_google_credentials'
      WHEN lower(notes) LIKE '%gmail%' THEN 'gmail_other'
      ELSE 'email_other'
    END AS error_key
  FROM iterations
  WHERE agent = 'sanhedrin'
    AND task_id LIKE 'EMAIL%'
)
SELECT
  error_key,
  count(*) AS rows,
  min(ts) AS first_ts,
  max(ts) AS last_ts,
  sum(status = 'skip') AS skip_rows
FROM email
GROUP BY error_key
ORDER BY rows DESC;

.print ''
.print '== email-check rows by day =='
SELECT
  date(s.ts) AS day,
  count(*) AS email_rows,
  round(
    100.0 * count(*) /
    (
      SELECT count(*)
      FROM iterations s2
      WHERE s2.agent = 'sanhedrin'
        AND date(s2.ts) = date(s.ts)
    ),
    1
  ) AS pct_sanhedrin_day
FROM iterations s
WHERE s.agent = 'sanhedrin'
  AND s.task_id LIKE 'EMAIL%'
  AND s.ts LIKE '2026-%'
GROUP BY date(s.ts)
ORDER BY day;

.print ''
.print '== daily credential-missing rows and note variants =='
SELECT
  date(ts) AS day,
  count(*) AS email_rows,
  sum(
    CASE
      WHEN lower(notes) LIKE '%marta_google_client_id%'
        OR lower(notes) LIKE '%marta_google_client_secret%'
        THEN 1
      ELSE 0
    END
  ) AS missing_cred_rows,
  count(DISTINCT notes) AS note_variants
FROM iterations
WHERE agent = 'sanhedrin'
  AND task_id LIKE 'EMAIL%'
  AND ts LIKE '2026-%'
GROUP BY date(ts)
ORDER BY day;

.print ''
.print '== long same-error email-check streaks =='
WITH email AS (
  SELECT
    id,
    ts,
    task_id,
    status,
    notes,
    CASE
      WHEN lower(notes) LIKE '%marta_google_client_id%'
        OR lower(notes) LIKE '%marta_google_client_secret%'
        THEN 'missing_marta_google_credentials'
      WHEN lower(notes) LIKE '%gmail%' THEN 'gmail_other'
      ELSE 'email_other'
    END AS error_key,
    row_number() OVER (ORDER BY ts, id) AS rn
  FROM iterations
  WHERE agent = 'sanhedrin'
    AND task_id LIKE 'EMAIL%'
),
streaks AS (
  SELECT
    *,
    rn - row_number() OVER (PARTITION BY error_key ORDER BY ts, id) AS grp
  FROM email
)
SELECT
  error_key,
  count(*) AS streak_len,
  min(ts) AS start_ts,
  max(ts) AS end_ts,
  min(task_id) AS min_task,
  max(task_id) AS max_task
FROM streaks
GROUP BY error_key, grp
HAVING count(*) >= 25
ORDER BY streak_len DESC
LIMIT 20;

.print ''
.print '== email-check structured evidence nulls =='
SELECT
  count(*) AS rows,
  sum(error_msg IS NULL OR trim(error_msg) = '') AS null_error_msg,
  sum(validation_cmd IS NULL OR trim(validation_cmd) = '') AS null_validation_cmd,
  sum(validation_result IS NULL OR trim(validation_result) = '') AS null_validation_result,
  sum(duration_sec IS NULL) AS null_duration
FROM iterations
WHERE agent = 'sanhedrin'
  AND task_id LIKE 'EMAIL%';

.print ''
.print '== top email-check note variants =='
SELECT
  substr(notes, 1, 180) AS notes,
  count(*) AS rows
FROM iterations
WHERE agent = 'sanhedrin'
  AND task_id LIKE 'EMAIL%'
GROUP BY notes
ORDER BY rows DESC
LIMIT 10;
