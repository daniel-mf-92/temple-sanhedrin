-- Historical drift trend audit, read-only against temple-central.db.
-- Source DB: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Run from temple-sanhedrin:
--   sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-29-files-changed-delimiter-drift.sql

.headers on
.mode column

with builder as (
  select
    id,
    ts,
    agent,
    task_id,
    files_changed,
    lines_added,
    lines_removed,
    length(files_changed) - length(replace(files_changed, ',', '')) as comma_count,
    length(files_changed) - length(replace(files_changed, ';', '')) as semicolon_count
  from iterations
  where agent in ('modernization', 'inference')
)
select
  agent,
  count(*) as rows,
  min(ts) as first_ts,
  max(ts) as last_ts,
  sum(case when coalesce(trim(files_changed), '') = '' then 1 else 0 end) as missing_files_changed,
  sum(case when comma_count > 0 then 1 else 0 end) as comma_rows,
  sum(case when semicolon_count > 0 then 1 else 0 end) as semicolon_rows,
  sum(case when comma_count > 0 and semicolon_count > 0 then 1 else 0 end) as mixed_delimiter_rows,
  sum(case when comma_count = 0 and semicolon_count = 0 then 1 else 0 end) as single_or_unsplit_rows,
  count(distinct files_changed) as unique_files_changed_strings,
  max(length(files_changed)) as max_files_changed_len
from builder
group by agent
order by agent;

with builder as (
  select
    agent,
    files_changed,
    length(files_changed) - length(replace(files_changed, ',', '')) as comma_count,
    length(files_changed) - length(replace(files_changed, ';', '')) as semicolon_count
  from iterations
  where agent in ('modernization', 'inference')
)
select
  agent,
  count(*) as rows,
  sum(1 + comma_count) as comma_only_parser_tokens,
  sum(1 + comma_count + semicolon_count) as comma_or_semicolon_tokens,
  sum(semicolon_count) as tokens_missed_by_comma_only,
  sum(case when semicolon_count > 0 and comma_count = 0 then 1 else 0 end) as semicolon_only_rows,
  sum(case when semicolon_count > 0 and comma_count = 0 then semicolon_count else 0 end) as missed_tokens_in_semicolon_only_rows
from builder
group by agent
order by agent;

select
  agent,
  sum(case when files_changed like '%;%' and (files_changed like '%Kernel/%' or files_changed like '%src/%') then 1 else 0 end) as semicolon_core_rows,
  sum(case when files_changed like '%;%' and files_changed like '%tests/%' then 1 else 0 end) as semicolon_test_rows,
  sum(case when files_changed like '%;%' and files_changed like '%automation/%' then 1 else 0 end) as semicolon_automation_rows,
  sum(case when files_changed like '%;%' and files_changed like '%MASTER_TASKS.md%' then 1 else 0 end) as semicolon_master_tasks_rows
from iterations
where agent in ('modernization', 'inference')
group by agent
order by agent;

with classified as (
  select
    agent,
    case
      when files_changed like '%;%' then 'semicolon'
      when files_changed like '%,%' then 'comma'
      else 'single_or_unsplit'
    end as delimiter_class,
    lines_added,
    lines_removed
  from iterations
  where agent in ('modernization', 'inference')
)
select
  agent,
  delimiter_class,
  count(*) as rows,
  sum(lines_added) as lines_added,
  sum(lines_removed) as lines_removed,
  round(avg(lines_added), 1) as avg_lines_added
from classified
group by agent, delimiter_class
order by agent, delimiter_class;

select
  substr(ts, 1, 10) as day,
  agent,
  count(*) as rows,
  sum(case when files_changed like '%,%' then 1 else 0 end) as comma_rows,
  sum(case when files_changed like '%;%' then 1 else 0 end) as semicolon_rows,
  sum(case when files_changed not like '%,%' and files_changed not like '%;%' then 1 else 0 end) as single_or_unsplit_rows
from iterations
where agent in ('modernization', 'inference')
group by day, agent
order by day, agent;

select
  agent,
  task_id,
  ts,
  files_changed,
  lines_added,
  lines_removed
from iterations
where agent in ('modernization', 'inference')
  and files_changed like '%;%'
order by ts desc
limit 12;
