-- Historical QEMU safety evidence recording drift audit.
-- Source DB: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Run from temple-sanhedrin:
--   sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-28-qemu-safety-evidence-recording-drift.sql

.headers on
.mode column

with rows as (
  select
    id,
    ts,
    agent,
    task_id,
    status,
    validation_cmd,
    validation_result,
    notes,
    lower(coalesce(validation_cmd,'')) as cmd,
    lower(coalesce(validation_result,'')) as result,
    lower(coalesce(notes,'')) as note
  from iterations
  where agent in ('modernization','inference')
),
classified as (
  select
    *,
    case when cmd like '%qemu%' or result like '%qemu%' or note like '%qemu%' then 1 else 0 end as any_qemu,
    case when cmd like '%qemu-system%' then 1 else 0 end as direct_qemu_cmd,
    case
      when cmd like '%-nic none%' or cmd like '%-nic=none%'
        or cmd like '%-net none%' or cmd like '%-net=none%'
        or result like '%-nic none%' or result like '%-nic=none%'
        or result like '%-net none%' or result like '%-net=none%'
        or note like '%-nic none%' or note like '%-nic=none%'
        or note like '%-net none%' or note like '%-net=none%'
      then 1 else 0
    end as no_network_evidence,
    case
      when cmd like '%readonly=on%' or result like '%readonly=on%' or note like '%readonly=on%'
      then 1 else 0
    end as readonly_evidence,
    case when cmd like '%bash -n%' then 1 else 0 end as bash_n_validation,
    case
      when result like '%skipped%' or result like '%unavailable%'
        or note like '%skipped%' or note like '%unavailable%'
      then 1 else 0
    end as skipped_or_unavailable,
    case
      when result like '%remote%' or result like '%azure%'
        or cmd like '%ssh %' or cmd like '%azure%'
        or note like '%remote%' or note like '%azure%'
      then 1 else 0
    end as remote_evidence
  from rows
)
select
  agent,
  count(*) as rows,
  sum(any_qemu) as qemu_evidence_rows,
  sum(case when any_qemu=1 and direct_qemu_cmd=1 then 1 else 0 end) as direct_qemu_cmd_rows,
  sum(case when any_qemu=1 and no_network_evidence=1 then 1 else 0 end) as qemu_no_network_evidence_rows,
  sum(case when any_qemu=1 and readonly_evidence=1 then 1 else 0 end) as qemu_readonly_evidence_rows,
  sum(case when any_qemu=1 and bash_n_validation=1 then 1 else 0 end) as qemu_bash_n_rows,
  sum(case when any_qemu=1 and skipped_or_unavailable=1 then 1 else 0 end) as qemu_skipped_or_unavailable_rows,
  sum(case when any_qemu=1 and remote_evidence=1 then 1 else 0 end) as qemu_remote_evidence_rows
from classified
group by agent
order by agent;

with rows as (
  select
    substr(ts,1,10) as day,
    lower(coalesce(validation_cmd,'')) as cmd,
    lower(coalesce(validation_result,'')) as result,
    lower(coalesce(notes,'')) as note
  from iterations
  where agent='modernization'
),
classified as (
  select
    *,
    case when cmd like '%qemu%' or result like '%qemu%' or note like '%qemu%' then 1 else 0 end as any_qemu,
    case
      when cmd like '%-nic none%' or cmd like '%-nic=none%'
        or cmd like '%-net none%' or cmd like '%-net=none%'
        or result like '%-nic none%' or result like '%-nic=none%'
        or result like '%-net none%' or result like '%-net=none%'
        or note like '%-nic none%' or note like '%-nic=none%'
        or note like '%-net none%' or note like '%-net=none%'
      then 1 else 0
    end as no_network_evidence,
    case
      when cmd like '%readonly=on%' or result like '%readonly=on%' or note like '%readonly=on%'
      then 1 else 0
    end as readonly_evidence,
    case when cmd like '%bash -n%' then 1 else 0 end as bash_n_validation,
    case
      when result like '%skipped%' or result like '%unavailable%'
        or note like '%skipped%' or note like '%unavailable%'
      then 1 else 0
    end as skipped_or_unavailable
  from rows
)
select
  day,
  sum(any_qemu) as qemu_rows,
  sum(no_network_evidence) as no_network_evidence_rows,
  sum(readonly_evidence) as readonly_evidence_rows,
  sum(bash_n_validation) as bash_n_rows,
  sum(skipped_or_unavailable) as skipped_or_unavailable_rows
from classified
where any_qemu=1
group by day
order by day;

with rows as (
  select
    id,
    ts,
    task_id,
    status,
    validation_cmd,
    validation_result,
    notes,
    lower(coalesce(validation_cmd,'')) as cmd,
    lower(coalesce(validation_result,'')) as result,
    lower(coalesce(notes,'')) as note
  from iterations
  where agent='modernization'
),
classified as (
  select
    *,
    case when cmd like '%qemu%' or result like '%qemu%' or note like '%qemu%' then 1 else 0 end as any_qemu,
    case
      when cmd like '%-nic none%' or cmd like '%-nic=none%'
        or cmd like '%-net none%' or cmd like '%-net=none%'
        or result like '%-nic none%' or result like '%-nic=none%'
        or result like '%-net none%' or result like '%-net=none%'
        or note like '%-nic none%' or note like '%-nic=none%'
        or note like '%-net none%' or note like '%-net=none%'
      then 1 else 0
    end as no_network_evidence,
    case
      when result like '%remote%' or result like '%azure%'
        or cmd like '%ssh %' or cmd like '%azure%'
        or note like '%remote%' or note like '%azure%'
      then 1 else 0
    end as remote_evidence
  from rows
)
select
  id,
  ts,
  task_id,
  status,
  no_network_evidence,
  remote_evidence,
  substr(validation_cmd,1,140) as validation_cmd_prefix,
  substr(validation_result,1,140) as validation_result_prefix
from classified
where any_qemu=1
order by id
limit 40;

with rows as (
  select
    id,
    ts,
    task_id,
    status,
    validation_cmd,
    validation_result,
    notes,
    lower(coalesce(validation_cmd,'')) as cmd,
    lower(coalesce(validation_result,'')) as result,
    lower(coalesce(notes,'')) as note
  from iterations
  where agent='modernization'
),
classified as (
  select
    *,
    case when cmd like '%qemu%' or result like '%qemu%' or note like '%qemu%' then 1 else 0 end as any_qemu,
    case
      when cmd like '%-nic none%' or cmd like '%-nic=none%'
        or cmd like '%-net none%' or cmd like '%-net=none%'
        or result like '%-nic none%' or result like '%-nic=none%'
        or result like '%-net none%' or result like '%-net=none%'
        or note like '%-nic none%' or note like '%-nic=none%'
        or note like '%-net none%' or note like '%-net=none%'
      then 1 else 0
    end as no_network_evidence,
    case
      when cmd like '%readonly=on%' or result like '%readonly=on%' or note like '%readonly=on%'
      then 1 else 0
    end as readonly_evidence
  from rows
)
select
  id,
  ts,
  task_id,
  status,
  no_network_evidence,
  readonly_evidence,
  substr(validation_cmd,1,160) as validation_cmd_prefix,
  substr(validation_result,1,160) as validation_result_prefix
from classified
where any_qemu=1
  and (no_network_evidence=1 or readonly_evidence=1)
order by id
limit 40;
