-- Historical builder change-accounting drift queries.
-- Database: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Scope: read-only trend evidence for Law 5 / auditability scoring.

.headers on
.mode column

select
  'builder_row_counts' as section,
  agent,
  count(*) as rows,
  sum(validation_cmd is null or trim(validation_cmd) = '') as blank_validation_cmd,
  sum(validation_result is null or trim(validation_result) = '') as blank_validation_result,
  sum(files_changed is null or trim(files_changed) = '') as blank_files_changed,
  sum(lines_added = 0 and lines_removed = 0) as zero_churn_rows,
  round(avg(lines_added + lines_removed), 1) as avg_churn
from iterations
where agent in ('modernization', 'inference')
group by agent;

select
  'daily_zero_churn' as section,
  agent,
  date(ts) as day,
  count(*) as rows,
  sum(lines_added = 0 and lines_removed = 0) as zero_churn_rows,
  round(100.0 * sum(lines_added = 0 and lines_removed = 0) / count(*), 2) as zero_pct,
  round(avg(lines_added + lines_removed), 1) as avg_churn
from iterations
where agent in ('modernization', 'inference')
group by agent, date(ts)
order by day, agent;

select
  'zero_churn_claim_shape' as section,
  agent,
  count(*) as zero_rows,
  sum(
    lower(notes) like '%added%' or
    lower(notes) like '%implemented%' or
    lower(notes) like '%hardened%' or
    lower(notes) like '%fixed%'
  ) as claimed_change_rows,
  sum(files_changed like '%MASTER_TASKS%' and files_changed not like '%,%' and files_changed not like '%;%') as task_only_rows,
  sum(files_changed = '(superseded)') as superseded_rows
from iterations
where agent in ('modernization', 'inference')
  and lines_added = 0
  and lines_removed = 0
group by agent;

select
  'zero_churn_rows' as section,
  id,
  ts,
  agent,
  task_id,
  status,
  files_changed,
  validation_result,
  notes
from iterations
where agent in ('modernization', 'inference')
  and lines_added = 0
  and lines_removed = 0
order by agent, ts;

select
  'large_churn_outliers' as section,
  id,
  ts,
  agent,
  task_id,
  lines_added,
  lines_removed,
  substr(files_changed, 1, 120) as files_changed_prefix,
  substr(notes, 1, 160) as notes_prefix
from iterations
where agent in ('modernization', 'inference')
  and (lines_added + lines_removed) > 1000
order by (lines_added + lines_removed) desc;

select
  'task_id_shape' as section,
  agent,
  count(*) as rows,
  sum(task_id like 'CQ-%' or task_id like 'IQ-%') as queue_like_rows,
  sum(task_id not like 'CQ-%' and task_id not like 'IQ-%') as non_queue_like_rows
from iterations
where agent in ('modernization', 'inference')
group by agent;
