-- Historical drift trend audit, read-only against temple-central.db.
-- Source DB: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Run from temple-sanhedrin:
--   sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-28-compound-name-task-reuse-drift.sql

.headers on
.mode column

select
  agent,
  status,
  count(*) as rows,
  min(ts) as first_ts,
  max(ts) as last_ts,
  sum(lines_added) as lines_added,
  sum(lines_removed) as lines_removed
from iterations
where agent in ('modernization','inference')
group by agent, status
order by agent, status;

with task_attempts as (
  select
    agent,
    task_id,
    count(*) as attempts,
    sum(status='pass') as pass_rows,
    sum(status!='pass') as nonpass_rows,
    min(ts) as first_ts,
    max(ts) as last_ts
  from iterations
  where agent in ('modernization','inference')
  group by agent, task_id
)
select
  agent,
  count(*) as unique_tasks,
  sum(attempts > 1) as reused_tasks,
  sum(attempts >= 3) as tasks_3plus,
  max(attempts) as max_attempts,
  round(avg(attempts), 2) as avg_attempts
from task_attempts
group by agent
order by agent;

with task_attempts as (
  select
    agent,
    task_id,
    count(*) as attempts,
    sum(status='pass') as pass_rows,
    sum(status!='pass') as nonpass_rows,
    min(ts) as first_ts,
    max(ts) as last_ts
  from iterations
  where agent in ('modernization','inference')
  group by agent, task_id
)
select *
from task_attempts
where attempts >= 3
order by attempts desc, agent, task_id
limit 40;

with recursive
file_split(row_id, ts, agent, task_id, rest, file_path) as (
  select
    id,
    ts,
    agent,
    task_id,
    replace(replace(coalesce(files_changed,''), ';', ','), char(10), ',') || ',',
    ''
  from iterations
  where agent in ('modernization','inference')
  union all
  select
    row_id,
    ts,
    agent,
    task_id,
    substr(rest, instr(rest, ',') + 1),
    trim(substr(rest, 1, instr(rest, ',') - 1))
  from file_split
  where rest <> ''
),
path_parts(row_id, ts, agent, task_id, file_path, rest, basename) as (
  select
    row_id,
    ts,
    agent,
    task_id,
    file_path,
    file_path || '/',
    ''
  from file_split
  where file_path <> ''
  union all
  select
    row_id,
    ts,
    agent,
    task_id,
    file_path,
    substr(rest, instr(rest, '/') + 1),
    substr(rest, 1, instr(rest, '/') - 1)
  from path_parts
  where rest <> ''
),
files as (
  select
    row_id,
    ts,
    agent,
    task_id,
    file_path,
    basename,
    length(basename) as basename_len,
    case
      when basename = '' then 0
      else length(basename) - length(replace(replace(basename, '-', ''), '_', '')) + 1
    end as token_estimate
  from path_parts
  where rest = ''
    and basename <> ''
)
select
  agent,
  count(*) as file_events,
  sum(basename_len > 40) as long_name_events,
  sum(token_estimate > 5) as many_token_events,
  count(distinct case when basename_len > 40 then row_id end) as rows_with_long_names,
  count(distinct case when token_estimate > 5 then row_id end) as rows_with_many_tokens,
  count(distinct case when basename_len > 40 then basename end) as unique_long_basenames,
  count(distinct case when token_estimate > 5 then basename end) as unique_many_token_basenames
from files
group by agent
order by agent;

with recursive
file_split(row_id, ts, agent, task_id, rest, file_path) as (
  select
    id,
    ts,
    agent,
    task_id,
    replace(replace(coalesce(files_changed,''), ';', ','), char(10), ',') || ',',
    ''
  from iterations
  where agent in ('modernization','inference')
  union all
  select
    row_id,
    ts,
    agent,
    task_id,
    substr(rest, instr(rest, ',') + 1),
    trim(substr(rest, 1, instr(rest, ',') - 1))
  from file_split
  where rest <> ''
),
path_parts(row_id, ts, agent, task_id, file_path, rest, basename) as (
  select row_id, ts, agent, task_id, file_path, file_path || '/', ''
  from file_split
  where file_path <> ''
  union all
  select
    row_id,
    ts,
    agent,
    task_id,
    file_path,
    substr(rest, instr(rest, '/') + 1),
    substr(rest, 1, instr(rest, '/') - 1)
  from path_parts
  where rest <> ''
),
files as (
  select
    row_id,
    ts,
    agent,
    task_id,
    basename,
    length(basename) as basename_len,
    case
      when basename = '' then 0
      else length(basename) - length(replace(replace(basename, '-', ''), '_', '')) + 1
    end as token_estimate
  from path_parts
  where rest = ''
    and basename <> ''
)
select
  substr(ts, 1, 10) as day,
  agent,
  count(distinct row_id) as rows,
  count(distinct case when basename_len > 40 or token_estimate > 5 then row_id end) as rows_with_compound_name_evidence
from files
group by day, agent
order by day, agent;

select
  count(*) as queue_rows
from queue;
