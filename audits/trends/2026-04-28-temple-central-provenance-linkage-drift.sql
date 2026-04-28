-- Historical provenance-linkage trend audit, read-only against temple-central.db.
-- Source DB: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Run from temple-sanhedrin:
--   sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-28-temple-central-provenance-linkage-drift.sql
--
-- Companion git commands used for post-DB comparison:
--   git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS log --format='%H' --since='2026-04-23T12:06:44+02:00' | wc -l
--   git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference log --format='%H' --since='2026-04-23T12:06:44+02:00' | wc -l

.headers on
.mode column

select
  name,
  sql
from sqlite_master
where type='table'
order by name;

select
  agent,
  count(*) as rows,
  min(ts) as first_ts,
  max(ts) as last_ts,
  count(distinct task_id) as distinct_tasks,
  sum(case when coalesce(trim(task_id),'')='' then 1 else 0 end) as missing_task,
  sum(case when coalesce(trim(files_changed),'')='' then 1 else 0 end) as missing_files,
  sum(case when coalesce(trim(notes),'')='' then 1 else 0 end) as missing_notes,
  sum(case
        when lower(coalesce(notes,'')) like '%commit%'
          or lower(coalesce(notes,'')) like '%sha%'
        then 1 else 0
      end) as notes_commit_mentions
from iterations
where agent in ('modernization','inference')
group by agent
order by agent;

with task_counts as (
  select
    agent,
    task_id,
    count(*) as n
  from iterations
  where agent in ('modernization','inference')
  group by agent, task_id
)
select
  agent,
  count(*) as tasks,
  sum(case when n=1 then 1 else 0 end) as once,
  sum(case when n=2 then 1 else 0 end) as twice,
  sum(case when n between 3 and 4 then 1 else 0 end) as three_four,
  sum(case when n>=5 then 1 else 0 end) as five_plus,
  max(n) as max_rows_per_task
from task_counts
group by agent
order by agent;

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
having count(*) >= 5
order by rows desc, agent
limit 40;

select
  agent,
  substr(ts,1,10) as day,
  count(*) as rows,
  round(100.0 * count(distinct task_id) / count(*), 1) as task_uniqueness_pct,
  round(1.0 * sum(lines_added + lines_removed) / count(*), 1) as avg_churn
from iterations
where agent in ('modernization','inference')
group by agent, substr(ts,1,10)
order by agent, day;

select
  agent,
  status,
  count(*) as rows,
  sum(case when coalesce(trim(error_msg),'')<>'' then 1 else 0 end) as with_error,
  sum(case when coalesce(trim(notes),'')<>'' then 1 else 0 end) as with_notes
from iterations
where agent in ('modernization','inference')
group by agent, status
order by agent, status;

