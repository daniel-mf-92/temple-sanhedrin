-- Historical trend audit: temple-central violation-ledger null drift.
-- Read-only query pack for:
-- /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db

.headers on
.mode column

select
  (select count(*) from laws) as law_rows,
  (select count(*) from violations) as violation_rows,
  (select count(*) from iterations) as iteration_rows;

select
  agent,
  status,
  count(*) as rows,
  sum(case when error_msg is null or trim(error_msg) = '' then 1 else 0 end) as rows_without_error_msg,
  min(ts) as first_ts,
  max(ts) as last_ts
from iterations
group by agent, status
order by agent, status;

select
  status,
  count(*) as sanhedrin_rows,
  sum(case when error_msg is null or trim(error_msg) = '' then 1 else 0 end) as rows_without_error_msg,
  sum(case when validation_cmd is null or trim(validation_cmd) = '' then 1 else 0 end) as rows_without_validation_cmd,
  sum(case when validation_result is null or trim(validation_result) = '' then 1 else 0 end) as rows_without_validation_result,
  sum(case when duration_sec is null then 1 else 0 end) as rows_without_duration
from iterations
where agent = 'sanhedrin'
group by status
order by status;

select
  date(ts) as day,
  count(*) as sanhedrin_rows,
  sum(case when status = 'fail' then 1 else 0 end) as fail_rows,
  sum(case when status = 'blocked' then 1 else 0 end) as blocked_rows,
  sum(case when status = 'skip' then 1 else 0 end) as skip_rows,
  sum(case when status = 'fail' and (error_msg is null or trim(error_msg) = '') then 1 else 0 end) as fail_rows_without_error_msg
from iterations
where agent = 'sanhedrin'
  and date(ts) is not null
group by date(ts)
order by day;

select
  agent,
  count(*) as rows,
  sum(case when validation_cmd is null or trim(validation_cmd) = '' then 1 else 0 end) as rows_without_validation_cmd,
  sum(case when validation_result is null or trim(validation_result) = '' then 1 else 0 end) as rows_without_validation_result,
  sum(case when error_msg is null or trim(error_msg) = '' then 1 else 0 end) as rows_without_error_msg,
  sum(case when duration_sec is null then 1 else 0 end) as rows_without_duration
from iterations
group by agent
order by agent;

select
  id,
  ts,
  status,
  task_id,
  notes
from iterations
where agent = 'sanhedrin'
  and status in ('fail', 'blocked')
order by id
limit 25;
