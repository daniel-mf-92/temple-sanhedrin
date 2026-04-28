-- Historical drift trend audit, read-only against temple-central.db.
-- Source DB: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Run from temple-sanhedrin:
--   sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-28-validation-evidence-quality-drift.sql

.headers on
.mode column

select
  agent,
  count(*) as rows,
  min(ts) as first_ts,
  max(ts) as last_ts,
  sum(lines_added) as lines_added,
  sum(lines_removed) as lines_removed
from iterations
where agent in ('modernization','inference')
group by agent
order by agent;

select
  agent,
  status,
  count(*) as rows,
  sum(case when coalesce(trim(validation_cmd),'')='' then 1 else 0 end) as missing_cmd,
  sum(case when coalesce(trim(validation_result),'')='' then 1 else 0 end) as missing_result,
  sum(case when coalesce(trim(validation_cmd),'')<>'' and coalesce(trim(validation_result),'')='' then 1 else 0 end) as cmd_no_result,
  sum(case when lower(coalesce(validation_result,'')) like '%pass%' then 1 else 0 end) as result_mentions_pass,
  sum(case when lower(coalesce(validation_result,'')) like '%fail%'
         or lower(coalesce(validation_result,'')) like '%error%' then 1 else 0 end) as result_mentions_fail_error
from iterations
where agent in ('modernization','inference')
group by agent,status
order by agent,status;

with classified as (
  select
    agent,
    case
      when validation_result in ('exit 0','ok') then 'generic'
      when lower(validation_result) like '%skipped%'
        or lower(validation_result) like '%unavailable%' then 'skipped_or_unavailable'
      when lower(validation_result) like '%passed%'
        or lower(validation_result) like '%checks=ok%'
        or lower(validation_result) like '%=ok%' then 'specific_pass'
      else 'other'
    end as class
  from iterations
  where agent in ('modernization','inference')
)
select
  agent,
  class,
  count(*) as rows,
  round(100.0 * count(*) / sum(count(*)) over (partition by agent), 2) as pct
from classified
group by agent,class
order by agent, rows desc;

select
  agent,
  count(*) as rows,
  sum(case when lower(validation_cmd) like '%qemu%' then 1 else 0 end) as qemu_cmd_rows,
  sum(case when lower(validation_result) like '%skipped%'
         or lower(validation_result) like '%unavailable%' then 1 else 0 end) as skipped_or_unavailable_results,
  sum(case when lower(validation_cmd) like '%qemu%'
         and (lower(validation_result) like '%skipped%'
              or lower(validation_result) like '%unavailable%') then 1 else 0 end) as qemu_cmd_skipped_results
from iterations
where agent in ('modernization','inference')
group by agent
order by agent;

select
  substr(ts,1,10) as day,
  count(*) as rows,
  sum(case when lower(validation_cmd) like '%qemu%' then 1 else 0 end) as qemu_cmd_rows,
  sum(case when lower(validation_cmd) like '%qemu%'
         and (lower(validation_result) like '%skipped%'
              or lower(validation_result) like '%unavailable%') then 1 else 0 end) as qemu_skipped
from iterations
where agent='modernization'
group by day
order by day;

with by_day as (
  select
    substr(ts,1,10) as day,
    sum(case when lower(validation_cmd) like '%qemu%' then 1 else 0 end) as qemu_cmd_rows,
    sum(case when lower(validation_cmd) like '%qemu%'
           and (lower(validation_result) like '%skipped%'
                or lower(validation_result) like '%unavailable%') then 1 else 0 end) as qemu_skipped
  from iterations
  where agent='modernization'
  group by day
)
select
  day,
  qemu_cmd_rows,
  qemu_skipped,
  round(100.0 * qemu_skipped / nullif(qemu_cmd_rows,0), 2) as pct_qemu_skipped
from by_day
order by pct_qemu_skipped desc, day
limit 10;

select
  validation_result,
  count(*) as rows,
  min(ts) as first_ts,
  max(ts) as last_ts
from iterations
where agent='modernization'
  and lower(validation_cmd) like '%qemu%'
  and (lower(validation_result) like '%skipped%'
       or lower(validation_result) like '%unavailable%')
group by validation_result
order by rows desc, validation_result;

select
  agent,
  count(distinct validation_cmd) as unique_cmds,
  count(distinct validation_result) as unique_results,
  sum(case when length(validation_cmd)>500 then 1 else 0 end) as cmd_gt_500,
  sum(case when length(validation_cmd)>1000 then 1 else 0 end) as cmd_gt_1000,
  max(length(validation_cmd)) as max_cmd_len,
  round(avg(length(validation_cmd)),1) as avg_cmd_len,
  max(length(validation_result)) as max_result_len,
  round(avg(length(validation_result)),1) as avg_result_len
from iterations
where agent in ('modernization','inference')
group by agent
order by agent;
