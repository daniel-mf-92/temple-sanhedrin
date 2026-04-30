-- Historical local QEMU skip-as-pass drift queries.
-- Database: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Scope: read-only trend evidence for Law 2 / Law 5 validation-quality scoring.

.headers on
.mode column

select
  'builder_window' as section,
  min(ts) as first_ts,
  max(ts) as last_ts,
  count(*) as builder_rows,
  sum(agent = 'modernization') as modernization_rows,
  sum(agent = 'inference') as inference_rows
from iterations
where agent in ('modernization', 'inference');

select
  'agent_skip_summary' as section,
  agent,
  count(*) as rows,
  sum(status = 'pass') as pass_rows,
  sum(status = 'pass' and lower(validation_result) like '%skip%') as pass_skip_rows,
  sum(status = 'pass' and lower(validation_result) like '%iso%') as pass_iso_rows,
  sum(status = 'pass' and lower(validation_result) like '%skip%' and lower(validation_result) like '%iso%') as pass_iso_skip_rows,
  sum(status = 'pass' and lower(validation_cmd) like '%qemu-compile-test%') as pass_qemu_compile_cmd_rows,
  sum(status = 'pass' and lower(validation_cmd) like '%ssh%') as pass_ssh_cmd_rows
from iterations
where agent in ('modernization', 'inference')
group by agent;

select
  'modernization_daily_iso_skip' as section,
  date(ts) as day,
  count(*) as rows,
  sum(status = 'pass' and lower(validation_result) like '%skip%' and lower(validation_result) like '%iso%') as iso_skip_pass_rows,
  sum(status = 'pass' and lower(validation_result) like '%skip%' and lower(validation_result) like '%iso%' and lower(validation_cmd) like '%ssh%') as iso_skip_with_ssh,
  sum(status = 'pass' and lower(validation_result) like '%skip%' and lower(validation_result) like '%iso%' and lower(validation_cmd) not like '%ssh%') as iso_skip_no_ssh
from iterations
where agent = 'modernization'
group by date(ts)
order by day;

select
  'iso_skip_change_surface' as section,
  count(*) as iso_skip_pass_rows,
  sum(lower(files_changed) like '%kernel/%') as kernel_rows,
  sum(lower(files_changed) like '%bookoftruth%') as bookoftruth_rows,
  sum(lower(validation_cmd) like '%qemu-compile-test%') as qemu_compile_cmd_rows,
  sum(lower(validation_cmd) like '%ssh%') as ssh_cmd_rows,
  sum(lower(validation_result) like '%remote%' or lower(validation_result) like '%azure%') as remote_result_rows,
  sum(lower(notes) like '%added%' or lower(notes) like '%implemented%' or lower(notes) like '%hardened%' or lower(notes) like '%fixed%') as implementation_claim_rows
from iterations
where agent = 'modernization'
  and status = 'pass'
  and lower(validation_result) like '%skip%'
  and lower(validation_result) like '%iso%';

select
  'iso_skip_first_rows' as section,
  id,
  ts,
  task_id,
  substr(files_changed, 1, 100) as files_changed_prefix,
  substr(validation_result, 1, 120) as validation_result_prefix
from iterations
where agent = 'modernization'
  and status = 'pass'
  and lower(validation_result) like '%skip%'
  and lower(validation_result) like '%iso%'
order by ts
limit 12;

select
  'iso_skip_latest_rows' as section,
  id,
  ts,
  task_id,
  substr(files_changed, 1, 100) as files_changed_prefix,
  substr(validation_result, 1, 120) as validation_result_prefix
from iterations
where agent = 'modernization'
  and status = 'pass'
  and lower(validation_result) like '%skip%'
  and lower(validation_result) like '%iso%'
order by ts desc
limit 12;
