-- Historical drift trend audit, read-only against temple-central.db.
-- Source DB: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Run from temple-sanhedrin:
--   sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-27-temple-central-long-window-agent-behaviour.sql

.headers on
.mode column

select
  agent,
  count(*) as iterations,
  min(ts) as first_ts,
  max(ts) as last_ts,
  sum(case when status='pass' then 1 else 0 end) as pass,
  sum(case when status='blocked' then 1 else 0 end) as blocked,
  sum(case when status='fail' then 1 else 0 end) as fail,
  sum(case when status='skip' then 1 else 0 end) as skip
from iterations
group by agent
order by agent;

select
  substr(ts,1,10) as day,
  agent,
  count(*) as n,
  sum(status='pass') as pass,
  sum(status='fail') as fail,
  sum(status='blocked') as blocked,
  sum(status='skip') as skip,
  sum(lines_added) as added,
  sum(lines_removed) as removed
from iterations
group by day, agent
order by day, agent;

select
  agent,
  count(*) as rows,
  count(distinct task_id) as distinct_tasks,
  count(*) - count(distinct task_id) as duplicate_task_rows
from iterations
where agent in ('modernization','inference')
group by agent;

with repeated as (
  select agent, task_id, count(*) as n
  from iterations
  where agent in ('modernization','inference')
  group by agent, task_id
  having count(*) > 1
)
select
  agent,
  count(*) as repeated_task_ids,
  sum(n) as repeated_rows,
  max(n) as max_repeats
from repeated
group by agent;

select
  agent,
  task_id,
  count(*) as n,
  min(ts) as first_ts,
  max(ts) as last_ts
from iterations
where agent in ('modernization','inference')
group by agent, task_id
having count(*) > 1
order by n desc, agent, task_id
limit 30;

select
  task_id,
  status,
  count(*) as n,
  min(ts) as first_ts,
  max(ts) as last_ts
from iterations
where agent='sanhedrin'
group by task_id, status
order by n desc
limit 40;

select
  agent,
  count(*) as total,
  sum(validation_cmd is null or validation_cmd='') as missing_cmd,
  sum(validation_result is null or validation_result='') as missing_result,
  sum(notes is null or notes='') as missing_notes,
  sum(files_changed is null or files_changed='') as missing_files
from iterations
group by agent;

select
  agent,
  count(*) as total,
  sum(duration_sec is null) as missing_duration,
  min(duration_sec) as min_duration,
  avg(duration_sec) as avg_duration,
  max(duration_sec) as max_duration
from iterations
group by agent;

select count(*) as non_iso_ts
from iterations
where ts not glob '????-??-??T??:??:??*';

select
  topic,
  count(*) as n,
  min(ts) as first_ts,
  max(ts) as last_ts
from research
group by topic
order by n desc
limit 20;

select count(*) as violation_rows from violations;
select count(*) as law_rows from laws;
select count(*) as queue_rows from queue;
select count(*) as research_rows from research;
