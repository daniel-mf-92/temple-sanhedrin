-- Historical drift trend audit, read-only against temple-central.db.
-- Source DB: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Run from temple-sanhedrin:
--   sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-29-task-id-monotonicity-drift.sql

.headers on
.mode column

with parsed as (
  select
    id,
    ts,
    agent,
    task_id,
    case when agent = 'modernization' then 'CQ-' else 'IQ-' end as expected_prefix,
    case
      when agent = 'modernization' and task_id glob 'CQ-[0-9]*' then 1
      when agent = 'inference' and task_id glob 'IQ-[0-9]*' then 1
      else 0
    end as has_expected_prefix,
    cast(substr(task_id, 4) as integer) as task_num,
    case
      when task_id like '%/%'
        or task_id like '%,%'
        or task_id like '%+%'
        or lower(task_id) like '% and %'
      then 1 else 0
    end as is_composite
  from iterations
  where agent in ('modernization', 'inference')
),
single_task_sequence as (
  select
    *,
    lag(task_id) over(partition by agent order by ts, id) as prev_task_id,
    lag(task_num) over(partition by agent order by ts, id) as prev_task_num
  from parsed
  where has_expected_prefix = 1
    and is_composite = 0
),
repeated as (
  select
    agent,
    task_id,
    count(*) as row_count
  from parsed
  group by agent, task_id
  having count(*) > 1
)
select
  p.agent,
  count(*) as rows,
  min(p.ts) as first_ts,
  max(p.ts) as last_ts,
  count(distinct p.task_id) as distinct_task_ids,
  sum(case when p.has_expected_prefix = 1 then 1 else 0 end) as expected_prefix_rows,
  sum(case when p.is_composite = 1 then 1 else 0 end) as composite_rows,
  (select count(*) from repeated r where r.agent = p.agent) as repeated_task_ids,
  (select sum(r.row_count) from repeated r where r.agent = p.agent) as rows_using_repeated_task_ids,
  (
    select count(*)
    from single_task_sequence s
    where s.agent = p.agent
      and s.prev_task_num is not null
      and s.task_num <= s.prev_task_num
  ) as non_increasing_steps,
  (
    select count(*)
    from single_task_sequence s
    where s.agent = p.agent
      and s.prev_task_num is not null
      and s.task_num < s.prev_task_num
  ) as backwards_steps
from parsed p
group by p.agent
order by p.agent;

with repeated as (
  select
    agent,
    task_id,
    count(*) as row_count
  from iterations
  where agent in ('modernization', 'inference')
  group by agent, task_id
  having count(*) > 1
)
select
  i.agent,
  count(distinct i.task_id) as repeated_task_ids,
  sum(case when coalesce(i.lines_added, 0) + coalesce(i.lines_removed, 0) > 0 then 1 else 0 end) as repeated_rows_with_line_changes,
  sum(coalesce(i.lines_added, 0)) as repeated_lines_added,
  sum(coalesce(i.lines_removed, 0)) as repeated_lines_removed
from iterations i
join repeated r
  on r.agent = i.agent
 and r.task_id = i.task_id
group by i.agent
order by i.agent;

select
  agent,
  task_id,
  count(*) as rows,
  min(ts) as first_ts,
  max(ts) as last_ts
from iterations
where agent in ('modernization', 'inference')
group by agent, task_id
having count(*) > 1
order by rows desc, agent, task_id
limit 20;

with parsed as (
  select
    id,
    ts,
    agent,
    task_id,
    cast(substr(task_id, 4) as integer) as task_num
  from iterations
  where agent in ('modernization', 'inference')
    and task_id not like '%/%'
    and task_id not like '%,%'
    and task_id not like '%+%'
    and lower(task_id) not like '% and %'
    and (
      (agent = 'modernization' and task_id glob 'CQ-[0-9]*')
      or (agent = 'inference' and task_id glob 'IQ-[0-9]*')
    )
),
sequenced as (
  select
    *,
    lag(task_id) over(partition by agent order by ts, id) as prev_task_id,
    lag(task_num) over(partition by agent order by ts, id) as prev_task_num
  from parsed
)
select
  agent,
  ts,
  task_id,
  prev_task_id,
  (prev_task_num - task_num) as drop_by
from sequenced
where prev_task_num is not null
  and task_num < prev_task_num
order by drop_by desc, ts
limit 16;

with parsed as (
  select
    id,
    ts,
    substr(ts, 1, 10) as day,
    agent,
    task_id,
    cast(substr(task_id, 4) as integer) as task_num,
    case
      when task_id like '%/%'
        or task_id like '%,%'
        or task_id like '%+%'
        or lower(task_id) like '% and %'
      then 1 else 0
    end as is_composite
  from iterations
  where agent in ('modernization', 'inference')
    and (
      (agent = 'modernization' and task_id glob 'CQ-[0-9]*')
      or (agent = 'inference' and task_id glob 'IQ-[0-9]*')
    )
),
single_task_sequence as (
  select
    *,
    lag(task_num) over(partition by agent order by ts, id) as prev_task_num
  from parsed
  where is_composite = 0
)
select
  p.day,
  p.agent,
  count(*) as rows,
  sum(p.is_composite) as composite_rows,
  sum(case when s.prev_task_num is not null and s.task_num <= s.prev_task_num then 1 else 0 end) as non_increasing_steps,
  sum(case when s.prev_task_num is not null and s.task_num < s.prev_task_num then 1 else 0 end) as backwards_steps
from parsed p
left join single_task_sequence s
  on s.id = p.id
group by p.day, p.agent
order by p.day, p.agent;

select
  id,
  ts,
  task_id,
  files_changed,
  substr(notes, 1, 110) as notes_excerpt
from iterations
where agent = 'modernization'
  and (
    task_id like '%/%'
    or task_id like '%,%'
    or task_id like '%+%'
    or lower(task_id) like '% and %'
  )
order by ts
limit 20;
