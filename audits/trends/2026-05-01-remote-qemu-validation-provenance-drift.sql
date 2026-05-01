-- Historical remote QEMU validation provenance drift audit.
-- Read-only analysis against /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db.

.headers on
.mode column

select
  count(*) as rows,
  min(ts) as min_ts,
  max(ts) as max_ts
from iterations;

select
  agent,
  count(*) as rows,
  min(ts) as first_ts,
  max(ts) as last_ts
from iterations
group by agent
order by rows desc;

with builder_rows as (
  select *
  from iterations
  where agent in ('modernization', 'inference')
)
select
  agent,
  count(*) as rows,
  sum(validation_cmd like '%qemu%') as qemu_rows,
  sum(validation_cmd like '%-nic none%' or validation_cmd like '%-net none%') as no_network_rows,
  sum(validation_cmd like '%ssh %'
      or validation_cmd like '%52.157.85.234%'
      or validation_cmd like '%azureuser@%') as remote_rows,
  sum(validation_cmd like '%curl %'
      or validation_cmd like '%http://%'
      or validation_cmd like '%https://%'
      or validation_cmd like '%wget %') as network_fetch_rows,
  sum(validation_cmd like '%qemu%'
      and not (
        validation_cmd like '%-nic none%'
        or validation_cmd like '%-net none%'
        or validation_cmd like '%qemu-compile-test.sh%'
        or validation_cmd like '%qemu-headless.sh%'
        or validation_cmd like '%qemu-smoke.sh%'
      )) as qemu_no_explicit_evidence_rows
from builder_rows
group by agent;

with builder_days as (
  select
    date(ts) as day,
    agent,
    validation_cmd
  from iterations
  where agent in ('modernization', 'inference')
)
select
  day,
  agent,
  count(*) as rows,
  sum(validation_cmd like '%qemu%') as qemu_rows,
  sum(validation_cmd like '%ssh %'
      or validation_cmd like '%52.157.85.234%'
      or validation_cmd like '%azureuser@%') as remote_rows,
  sum(validation_cmd like '%curl %'
      or validation_cmd like '%http://%'
      or validation_cmd like '%https://%'
      or validation_cmd like '%wget %') as network_fetch_rows
from builder_days
group by day, agent
having remote_rows > 0
   or network_fetch_rows > 0
   or qemu_rows > 0
order by day desc, agent;

with modernization_days as (
  select
    date(ts) as day,
    count(*) as rows,
    sum(validation_cmd like '%ssh %'
        or validation_cmd like '%52.157.85.234%'
        or validation_cmd like '%azureuser@%') as remote_rows
  from iterations
  where agent = 'modernization'
  group by date(ts)
)
select
  day,
  rows,
  remote_rows,
  round(100.0 * remote_rows / rows, 1) as remote_pct
from modernization_days
where remote_rows > 0
order by day;

with qemu_rows as (
  select *
  from iterations
  where agent in ('modernization', 'inference')
    and validation_cmd like '%qemu%'
)
select
  agent,
  status,
  count(*) as qemu_rows,
  sum(validation_cmd like '%-nic none%' or validation_cmd like '%-net none%') as explicit_no_network_rows,
  sum(validation_cmd like '%qemu-compile-test.sh%') as wrapper_compile_rows,
  sum(validation_cmd like '%qemu-headless.sh%') as wrapper_headless_rows,
  sum(validation_cmd like '%qemu-smoke.sh%') as wrapper_smoke_rows
from qemu_rows
group by agent, status;

select
  count(*) as malformed_ts
from iterations
where ts not glob '????-??-??T??:??:??';

select
  id,
  ts,
  agent,
  task_id,
  status,
  substr(notes, 1, 160) as notes
from iterations
where ts not glob '????-??-??T??:??:??'
order by id
limit 20;

