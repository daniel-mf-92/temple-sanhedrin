-- Historical drift audit: Book-of-Truth hardware-proximity evidence in temple-central.db.
-- Run read-only:
-- sqlite3 -readonly /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-29-bookoftruth-hardware-proximity-evidence-drift.sql

.headers on
.mode column

select
  count(*) as violation_rows
from violations;

select
  agent,
  count(*) as rows,
  min(ts) as first_ts,
  max(ts) as last_ts
from iterations
where agent in ('modernization', 'inference')
group by agent
order by agent;

select
  agent,
  count(*) as rows,
  sum(case when lower(coalesce(notes, '') || ' ' || coalesce(files_changed, '')) like '%book%truth%' then 1 else 0 end) as bot_notes_or_files,
  sum(case
    when lower(coalesce(validation_cmd, '') || ' ' || coalesce(validation_result, '')) like '%book%truth%'
      or lower(coalesce(validation_cmd, '') || ' ' || coalesce(validation_result, '')) like '%bookoftruth%'
    then 1 else 0
  end) as bot_validation,
  sum(case
    when lower(coalesce(validation_cmd, '') || ' ' || coalesce(validation_result, '')) like '%serial%'
      or lower(coalesce(validation_cmd, '') || ' ' || coalesce(validation_result, '')) like '%uart%'
    then 1 else 0
  end) as serial_validation,
  sum(case when lower(coalesce(notes, '') || ' ' || coalesce(validation_cmd, '') || ' ' || coalesce(validation_result, '') || ' ' || coalesce(files_changed, '')) like '%0x3f8%' then 1 else 0 end) as literal_0x3f8,
  sum(case when lower(coalesce(notes, '') || ' ' || coalesce(validation_cmd, '') || ' ' || coalesce(validation_result, '') || ' ' || coalesce(files_changed, '')) like '%rdtsc%' then 1 else 0 end) as rdtsc,
  sum(case when lower(coalesce(notes, '') || ' ' || coalesce(validation_cmd, '') || ' ' || coalesce(validation_result, '') || ' ' || coalesce(files_changed, '')) like '%rdmsr%' then 1 else 0 end) as rdmsr,
  sum(case
    when lower(coalesce(notes, '') || ' ' || coalesce(validation_cmd, '') || ' ' || coalesce(validation_result, '') || ' ' || coalesce(files_changed, '')) like '%inline%'
      or lower(coalesce(notes, '') || ' ' || coalesce(validation_cmd, '') || ' ' || coalesce(validation_result, '') || ' ' || coalesce(files_changed, '')) like '%synchronous%'
    then 1 else 0
  end) as proximity_terms
from iterations
where agent in ('modernization', 'inference')
group by agent
order by agent;

select
  substr(ts, 1, 10) as day,
  count(*) as rows,
  sum(case when lower(coalesce(notes, '') || ' ' || coalesce(files_changed, '')) like '%book%truth%' then 1 else 0 end) as bot_rows,
  sum(case
    when lower(coalesce(notes, '') || ' ' || coalesce(files_changed, '')) like '%serial%'
      or lower(coalesce(notes, '') || ' ' || coalesce(files_changed, '')) like '%uart%'
    then 1 else 0
  end) as serial_rows,
  sum(case when lower(coalesce(notes, '') || ' ' || coalesce(files_changed, '')) like '%0x3f8%' then 1 else 0 end) as uart_literal_rows,
  sum(case
    when lower(coalesce(notes, '') || ' ' || coalesce(files_changed, '')) like '%inline%'
      or lower(coalesce(notes, '') || ' ' || coalesce(files_changed, '')) like '%synchronous%'
    then 1 else 0
  end) as proximity_rows
from iterations
where agent = 'modernization'
  and ts glob '2026-*'
group by day
order by day;

select
  id,
  ts,
  agent,
  task_id,
  validation_cmd,
  validation_result,
  substr(notes, 1, 220) as notes
from iterations
where agent = 'modernization'
  and (
    lower(validation_cmd) like '%serial%'
    or lower(validation_result) like '%serial%'
    or lower(notes) like '%serial%'
    or lower(files_changed) like '%serial%'
    or lower(validation_cmd) like '%uart%'
    or lower(validation_result) like '%uart%'
    or lower(notes) like '%uart%'
    or lower(files_changed) like '%uart%'
  )
order by ts
limit 20;

select
  id,
  ts,
  agent,
  task_id,
  validation_cmd,
  validation_result,
  substr(notes, 1, 220) as notes
from iterations
where agent = 'modernization'
  and lower(coalesce(notes, '') || ' ' || coalesce(validation_cmd, '') || ' ' || coalesce(validation_result, '') || ' ' || coalesce(files_changed, '')) like '%inline%'
order by ts;
