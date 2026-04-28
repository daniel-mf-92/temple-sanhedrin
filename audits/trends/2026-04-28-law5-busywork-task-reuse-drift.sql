-- Historical Law 5 / queue-reuse trend audit, read-only against temple-central.db.
-- Source DB: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Run from temple-sanhedrin:
--   sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-28-law5-busywork-task-reuse-drift.sql

.headers on
.mode column

with class as (
  select
    id,
    ts,
    agent,
    task_id,
    files_changed,
    lines_added,
    lines_removed,
    validation_result,
    lower(coalesce(files_changed,'')) as f,
    case
      when lower(coalesce(files_changed,''))='master_tasks.md'
        or lower(coalesce(files_changed,''))='modernization/master_tasks.md'
      then 1 else 0
    end as only_master_tasks,
    case
      when coalesce(files_changed,'')<>''
        and lower(files_changed) not like '%.hc%'
        and lower(files_changed) not like '%.py%'
        and lower(files_changed) not like '%.sh%'
        and lower(files_changed) not like '%.sql%'
        and lower(files_changed) not like '%.json%'
        and lower(files_changed) not like '%.csv%'
        and lower(files_changed) not like '%.txt%'
        and lower(files_changed) like '%.md%'
      then 1 else 0
    end as doc_only,
    case
      when lower(coalesce(files_changed,'')) glob '*kernel/*.hc*'
        or lower(coalesce(files_changed,'')) glob '*src/*.hc*'
        or lower(coalesce(files_changed,'')) glob '*adam/*.hc*'
        or lower(coalesce(files_changed,'')) glob '*apps/*.hc*'
        or lower(coalesce(files_changed,'')) glob '*compiler/*.hc*'
      then 1 else 0
    end as touches_core_hc,
    case
      when lower(coalesce(files_changed,'')) like '%automation/%'
        or lower(coalesce(files_changed,'')) like '%tests/%'
      then 1 else 0
    end as touches_tooling_tests
  from iterations
  where agent in ('modernization','inference')
)
select
  agent,
  count(*) as rows,
  min(ts) as first_ts,
  max(ts) as last_ts,
  sum(doc_only) as doc_only_rows,
  round(100.0*sum(doc_only)/count(*),2) as pct_doc_only,
  sum(only_master_tasks) as only_master_tasks_rows,
  sum(case when only_master_tasks=1 and lines_added<=3 and lines_removed=0 then 1 else 0 end) as tiny_master_tasks_rows,
  sum(touches_core_hc) as core_hc_rows,
  sum(touches_tooling_tests) as tooling_test_rows
from class
group by agent
order by agent;

with class as (
  select
    id,
    ts,
    agent,
    task_id,
    files_changed,
    lines_added,
    lines_removed,
    case
      when lower(coalesce(files_changed,''))='master_tasks.md'
        or lower(coalesce(files_changed,''))='modernization/master_tasks.md'
      then 1 else 0
    end as only_master_tasks
  from iterations
  where agent in ('modernization','inference')
),
runs as (
  select
    *,
    sum(case when only_master_tasks=0 then 1 else 0 end)
      over (partition by agent order by id rows unbounded preceding) as grp
  from class
),
streaks as (
  select
    agent,
    grp,
    count(*) as len,
    min(ts) as first_ts,
    max(ts) as last_ts,
    group_concat(task_id, ',') as task_ids,
    sum(lines_added) as added,
    sum(lines_removed) as removed
  from runs
  where only_master_tasks=1
  group by agent, grp
)
select *
from streaks
where len>=2
order by len desc, first_ts;

select
  agent,
  task_id,
  count(*) as rows,
  min(ts) as first_ts,
  max(ts) as last_ts,
  sum(lines_added) as added,
  sum(lines_removed) as removed
from iterations
where agent in ('modernization','inference')
group by agent, task_id
having count(*)>=4
order by rows desc, agent, task_id
limit 25;

select
  agent,
  task_id,
  count(*) as master_only_rows,
  min(ts) as first_ts,
  max(ts) as last_ts,
  sum(lines_added) as added
from iterations
where agent in ('modernization','inference')
  and (
    lower(coalesce(files_changed,''))='master_tasks.md'
    or lower(coalesce(files_changed,''))='modernization/master_tasks.md'
  )
group by agent, task_id
having count(*)>=2
order by master_only_rows desc, first_ts;

with class as (
  select
    id,
    ts,
    agent,
    task_id,
    case
      when coalesce(files_changed,'')<>''
        and lower(files_changed) not like '%.hc%'
        and lower(files_changed) not like '%.py%'
        and lower(files_changed) not like '%.sh%'
        and lower(files_changed) not like '%.sql%'
        and lower(files_changed) not like '%.json%'
        and lower(files_changed) not like '%.csv%'
        and lower(files_changed) not like '%.txt%'
        and lower(files_changed) like '%.md%'
      then 1 else 0
    end as doc_only
  from iterations
  where agent in ('modernization','inference')
),
runs as (
  select
    *,
    sum(case when doc_only=0 then 1 else 0 end)
      over (partition by agent order by id rows unbounded preceding) as grp
  from class
),
streaks as (
  select
    agent,
    count(*) as len,
    min(ts) as first_ts,
    max(ts) as last_ts,
    group_concat(task_id, ',') as task_ids
  from runs
  where doc_only=1
  group by agent, grp
)
select
  agent,
  max(len) as max_doc_only_streak
from streaks
group by agent
order by agent;
