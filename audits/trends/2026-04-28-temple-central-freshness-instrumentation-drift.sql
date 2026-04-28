-- Historical drift trend audit, read-only against temple-central.db.
-- Source DB: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Run from temple-sanhedrin:
--   sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-28-temple-central-freshness-instrumentation-drift.sql

.headers on
.mode column

select 'iterations' as table_name, count(*) as rows, min(ts) as first_ts, max(ts) as last_ts from iterations
union all select 'violations', count(*), min(ts), max(ts) from violations
union all select 'research', count(*), min(ts), max(ts) from research
union all select 'queue', count(*), min(created_ts), max(created_ts) from queue;

select
  agent,
  count(*) as rows,
  min(ts) as first_ts,
  max(ts) as last_ts,
  round(julianday('2026-04-28T07:49:37') - julianday(max(ts)), 2) as days_stale_at_audit
from iterations
group by agent
order by agent;

select
  substr(ts, 1, 10) as day,
  agent,
  count(*) as rows,
  count(distinct task_id) as tasks,
  sum(lines_added) as lines_added,
  sum(lines_removed) as lines_removed,
  round(avg(duration_sec), 1) as avg_duration_sec,
  max(duration_sec) as max_duration_sec
from iterations
where agent in ('modernization', 'inference')
group by day, agent
order by day, agent;

select
  agent,
  sum(case when task_id like 'CQ-%' then 1 else 0 end) as cq_rows,
  sum(case when task_id like 'IQ-%' then 1 else 0 end) as iq_rows,
  sum(case when task_id not like 'CQ-%' and task_id not like 'IQ-%' then 1 else 0 end) as other_task_rows,
  count(distinct task_id) as distinct_tasks,
  min(task_id) as min_task_id,
  max(task_id) as max_task_id
from iterations
where agent in ('modernization', 'inference')
group by agent
order by agent;

select
  agent,
  count(*) as rows,
  sum(case when coalesce(trim(files_changed), '') = '' then 1 else 0 end) as missing_files_changed,
  sum(case when coalesce(duration_sec, 0) = 0 then 1 else 0 end) as zero_or_missing_duration,
  sum(case when coalesce(trim(notes), '') = '' then 1 else 0 end) as missing_notes,
  sum(case when coalesce(lines_added, 0) = 0 and coalesce(lines_removed, 0) = 0 then 1 else 0 end) as no_line_delta
from iterations
where agent in ('modernization', 'inference')
group by agent
order by agent;

select
  agent,
  count(*) as rows,
  sum(case when ts like '____-__-__T__:__:__%' then 1 else 0 end) as iso_like_rows,
  sum(case when ts not like '____-__-__T__:__:__%' then 1 else 0 end) as non_iso_rows,
  min(case when ts not like '____-__-__T__:__:__%' then ts end) as min_non_iso,
  max(case when ts not like '____-__-__T__:__:__%' then ts end) as max_non_iso
from iterations
group by agent
order by agent;

with recursive
file_split(row_id, ts, agent, task_id, rest, file_path) as (
  select
    id,
    ts,
    agent,
    task_id,
    replace(replace(coalesce(files_changed, ''), ';', ','), char(10), ',') || ',',
    ''
  from iterations
  where agent in ('modernization', 'inference')
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
files as (
  select row_id, agent, file_path
  from file_split
  where file_path <> ''
),
ranked_paths as (
  select
    agent,
    file_path,
    count(*) as events,
    row_number() over (partition by agent order by count(*) desc, file_path) as path_rank
  from files
  group by agent, file_path
)
select
  agent,
  file_path,
  events
from ranked_paths
where path_rank <= 40
order by agent, path_rank;

with recursive
file_split(row_id, ts, agent, task_id, rest, file_path) as (
  select
    id,
    ts,
    agent,
    task_id,
    replace(replace(coalesce(files_changed, ''), ';', ','), char(10), ',') || ',',
    ''
  from iterations
  where agent in ('modernization', 'inference')
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
files as (
  select
    row_id,
    substr(ts, 1, 10) as day,
    agent,
    file_path,
    case
      when file_path glob '*.HC'
        or file_path glob '*.HH'
        or file_path like 'Kernel/%'
        or file_path like 'Adam/%'
        or file_path like 'Apps/%'
        or file_path like 'Compiler/%'
        or file_path like 'src/%'
      then 1 else 0
    end as core_source,
    case
      when file_path like 'tests/%'
        or file_path like '%/tests/%'
        or file_path like 'automation/%'
        or (file_path like 'bench/%' and file_path not like 'bench/results/%')
      then 1 else 0
    end as executable_surface
  from file_split
  where file_path <> ''
)
select
  day,
  agent,
  count(distinct row_id) as rows,
  count(distinct case when core_source = 1 then row_id end) as core_source_rows,
  count(distinct case when executable_surface = 1 then row_id end) as executable_surface_rows
from files
group by day, agent
order by day, agent;
