-- Historical drift audit: temple-central.db coverage and severity semantics.
-- Run read-only:
-- sqlite3 -readonly /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-28-temple-central-coverage-and-severity-drift.sql

.headers on
.mode column

select
  'table_coverage' as check_name,
  'iterations' as table_name,
  count(*) as rows,
  min(ts) as first_ts,
  max(ts) as last_ts
from iterations
union all
select
  'table_coverage',
  'violations',
  count(*),
  min(ts),
  max(ts)
from violations
union all
select
  'table_coverage',
  'queue',
  count(*),
  min(created_ts),
  max(created_ts)
from queue
union all
select
  'table_coverage',
  'research',
  count(*),
  min(ts),
  max(ts)
from research;

select
  agent,
  status,
  count(*) as rows,
  min(ts) as first_ts,
  max(ts) as last_ts
from iterations
group by agent, status
order by agent, status;

select
  agent,
  substr(ts, 1, 10) as day,
  count(*) as iterations,
  sum(case when status = 'pass' then 1 else 0 end) as pass,
  sum(case when status = 'fail' then 1 else 0 end) as fail,
  sum(case when status = 'blocked' then 1 else 0 end) as blocked,
  sum(case when status = 'skip' then 1 else 0 end) as skip
from iterations
where ts glob '2026-*'
group by agent, day
order by day, agent;

select
  agent,
  count(*) as malformed_ts_rows,
  min(ts) as min_raw_ts,
  max(ts) as max_raw_ts
from iterations
where ts not glob '____-__-__T__:__:__*'
  and ts not glob '2026-*'
group by agent;

select
  agent,
  count(*) as rows,
  sum(case when validation_cmd is null or trim(validation_cmd) = '' then 1 else 0 end) as missing_validation_cmd,
  sum(case when validation_result is null or trim(validation_result) = '' then 1 else 0 end) as missing_validation_result,
  sum(case when files_changed is null or trim(files_changed) = '' then 1 else 0 end) as missing_files_changed
from iterations
where ts glob '2026-*'
group by agent;

select
  status,
  count(*) as notes_with_critical
from iterations
where notes like '%Severity=CRITICAL%'
   or notes like '%Severity=critical%'
group by status;

select
  status,
  count(*) as notes_with_warning
from iterations
where notes like '%Severity=WARNING%'
   or notes like '%Severity=warning%'
group by status;

select
  topic,
  count(*) as repeats,
  min(ts) as first_ts,
  max(ts) as last_ts
from research
group by topic
having count(*) >= 3
order by repeats desc, topic
limit 20;
