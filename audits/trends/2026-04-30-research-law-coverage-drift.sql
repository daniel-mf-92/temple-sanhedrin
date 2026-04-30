-- Historical research-ledger LAWS.md coverage drift queries.
-- Database: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Scope: read-only trend evidence for deep-research coverage versus repeat-task remediation.

.headers on
.mode column

with tagged as (
  select
    id,
    ts,
    topic,
    trigger_task,
    findings,
    references_urls,
    lower(topic || ' ' || findings) as body
  from research
)
select
  'research_summary' as section,
  count(*) as rows,
  sum(
    body like '%repeat%' or
    body like '%stuck%' or
    body like '%loop%' or
    body like '%retry%'
  ) as repeat_loop_rows,
  sum(
    body like '%law%' or
    body like '%air-gap%' or
    body like '%network%' or
    body like '%holyc%' or
    body like '%book of truth%' or
    body like '%integer%' or
    body like '%float%' or
    body like '%qemu%' or
    body like '%serial%' or
    body like '%immutable%' or
    body like '%local access%'
  ) as law_safety_rows,
  sum(references_urls is null or trim(references_urls) = '') as blank_refs,
  min(ts) as first_ts,
  max(ts) as last_ts
from tagged;

with tagged as (
  select
    date(ts) as day,
    lower(topic || ' ' || findings) as body
  from research
)
select
  'daily_shape' as section,
  day,
  count(*) as rows,
  sum(
    body like '%repeat%' or
    body like '%stuck%' or
    body like '%loop%' or
    body like '%retry%'
  ) as repeat_loop_rows,
  sum(
    body like '%law%' or
    body like '%air-gap%' or
    body like '%network%' or
    body like '%holyc%' or
    body like '%book of truth%' or
    body like '%integer%' or
    body like '%float%' or
    body like '%qemu%' or
    body like '%serial%' or
    body like '%immutable%' or
    body like '%local access%'
  ) as law_safety_rows
from tagged
group by day
order by day;

with tagged as (
  select lower(topic || ' ' || findings) as body
  from research
)
select 'law1_holyc' as law_surface,
       sum(body like '%holyc%' or body like '%holy c%' or body like '% c-only%' or body like '%foreign language%') as matching_rows
from tagged
union all
select 'law2_airgap_network',
       sum(body like '%air-gap%' or body like '%network%' or body like '%socket%' or body like '%tcp%' or body like '%udp%' or body like '%dns%' or body like '%qemu%')
from tagged
union all
select 'law3_bot_immutability',
       sum(body like '%book of truth%' or body like '%immutab%' or body like '%hash chain%' or body like '%sealed%')
from tagged
union all
select 'law4_integer_purity',
       sum(body like '%integer%' or body like '%float%' or body like '%f32%' or body like '%f64%' or body like '%double%')
from tagged
union all
select 'law5_no_busywork',
       sum(body like '%busywork%' or body like '%meaningful progress%' or body like '%north star%')
from tagged
union all
select 'law6_queue_health',
       sum(body like '%queue%' or body like '% cq-%' or body like '% iq-%')
from tagged
union all
select 'law7_liveness',
       sum(body like '%liveness%' or body like '%heartbeat%' or body like '%process%' or body like '%stuck%')
from tagged
union all
select 'law8_hardware_proximity',
       sum(body like '%hardware proximity%' or body like '%uart%' or body like '%0x3f8%' or body like '%rdtsc%' or body like '%rdmsr%' or body like '%serial%')
from tagged
union all
select 'law9_resource_supremacy',
       sum(body like '%resource%' or body like '%memory pressure%' or body like '%hlt%' or body like '%crash%')
from tagged
union all
select 'law10_immutable_image',
       sum(body like '%immutable os%' or body like '%readonly%' or body like '%read-only%' or body like '%kexec%' or body like '%module loading%')
from tagged
union all
select 'law11_local_access',
       sum(body like '%local access%' or body like '%remote viewing%' or body like '%serial port output%' or body like '%usb%')
from tagged;

select
  'top_trigger_tasks' as section,
  trigger_task,
  count(*) as rows
from research
group by trigger_task
order by rows desc, trigger_task
limit 20;

with tagged as (
  select
    id,
    ts,
    trigger_task,
    topic,
    findings,
    lower(topic || ' ' || findings) as body
  from research
)
select
  'law_safety_rows' as section,
  id,
  ts,
  trigger_task,
  topic,
  substr(findings, 1, 120) as findings_prefix
from tagged
where body like '%law%'
   or body like '%air-gap%'
   or body like '%network%'
   or body like '%holyc%'
   or body like '%book of truth%'
   or body like '%integer%'
   or body like '%float%'
   or body like '%qemu%'
   or body like '%serial%'
   or body like '%immutable%'
   or body like '%local access%'
order by id;
