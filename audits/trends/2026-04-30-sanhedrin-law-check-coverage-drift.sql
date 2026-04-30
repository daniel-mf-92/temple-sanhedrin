-- Historical Sanhedrin law-check coverage drift queries.
-- Database: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Scope: read-only trend evidence from Sanhedrin AUDIT rows.

.headers on
.mode column

with audit as (
  select
    id,
    ts,
    case
      when ts glob '[0-9][0-9][0-9][0-9]-*' then ts
      else datetime(cast(ts as integer), 'unixepoch')
    end as nts,
    status,
    lower(coalesce(notes, '')) as notes
  from iterations
  where agent = 'sanhedrin'
    and task_id = 'AUDIT'
)
select
  'audit_window' as section,
  count(*) as audit_rows,
  min(nts) as first_ts_norm,
  max(nts) as last_ts_norm,
  sum(status = 'pass') as pass_rows,
  sum(status = 'fail') as fail_rows,
  sum(status = 'blocked') as blocked_rows,
  sum(status = 'skip') as skip_rows,
  sum(notes = '') as empty_notes
from audit;

with audit as (
  select lower(coalesce(notes, '')) as notes
  from iterations
  where agent = 'sanhedrin'
    and task_id = 'AUDIT'
)
select
  'law_number_coverage' as section,
  count(*) as audit_rows,
  sum(notes like '%severity=%' or notes like '%severity:%') as severity_rows,
  sum(notes like '%law1%' or notes like '%law 1%') as law1_rows,
  sum(notes like '%law2%' or notes like '%law 2%') as law2_rows,
  sum(notes like '%law3%' or notes like '%law 3%') as law3_rows,
  sum(notes like '%law4%' or notes like '%law 4%') as law4_rows,
  sum(notes like '%law5%' or notes like '%law 5%') as law5_rows,
  sum(notes like '%law6%' or notes like '%law 6%') as law6_rows,
  sum(notes like '%law7%' or notes like '%law 7%') as law7_rows,
  sum(notes like '%law8%' or notes like '%law 8%') as law8_rows,
  sum(notes like '%law9%' or notes like '%law 9%') as law9_rows,
  sum(notes like '%law10%' or notes like '%law 10%') as law10_rows,
  sum(notes like '%law11%' or notes like '%law 11%') as law11_rows
from audit;

with audit as (
  select
    date(case
      when ts glob '[0-9][0-9][0-9][0-9]-*' then ts
      else datetime(cast(ts as integer), 'unixepoch')
    end) as day,
    lower(coalesce(notes, '')) as notes
  from iterations
  where agent = 'sanhedrin'
    and task_id = 'AUDIT'
)
select
  'daily_law_coverage' as section,
  day,
  count(*) as rows,
  sum(notes like '%severity=%' or notes like '%severity:%') as severity_rows,
  sum(notes like '%law1%' or notes like '%law 1%') as law1,
  sum(notes like '%law2%' or notes like '%law 2%') as law2,
  sum(notes like '%law3%' or notes like '%law 3%') as law3,
  sum(notes like '%law4%' or notes like '%law 4%') as law4,
  sum(notes like '%law5%' or notes like '%law 5%') as law5,
  sum(notes like '%law6%' or notes like '%law 6%') as law6,
  sum(notes like '%law7%' or notes like '%law 7%') as law7
from audit
group by day
order by day;

with audit as (
  select lower(coalesce(notes, '')) as notes
  from iterations
  where agent = 'sanhedrin'
    and task_id = 'AUDIT'
)
select
  'semantic_bucket_coverage' as section,
  'book_truth_or_serial' as bucket,
  sum(notes like '%book%' or notes like '%serial%') as rows
from audit
union all
select
  'semantic_bucket_coverage',
  'airgap_or_network',
  sum(notes like '%airgap%' or notes like '%network%' or notes like '%nic%' or notes like '%ws8%')
from audit
union all
select
  'semantic_bucket_coverage',
  'immutable_or_readonly',
  sum(notes like '%immutable%' or notes like '%readonly%' or notes like '%read-only%')
from audit
union all
select
  'semantic_bucket_coverage',
  'local_access_or_remote',
  sum(notes like '%local access%' or notes like '%remote%' or notes like '%ssh%' or notes like '%azure%')
from audit
union all
select
  'semantic_bucket_coverage',
  'queue_or_liveness',
  sum(notes like '%queue%' or notes like '%heartbeat%' or notes like '%loops_alive%' or notes like '%liveness%')
from audit;

with audit as (
  select
    id,
    ts,
    status,
    notes,
    lower(coalesce(notes, '')) as notes_l
  from iterations
  where agent = 'sanhedrin'
    and task_id = 'AUDIT'
)
select
  'sample_law_keyed_rows' as section,
  id,
  ts,
  status,
  substr(notes, 1, 240) as notes_prefix
from audit
where notes_l like '%law1%'
   or notes_l like '%law2%'
   or notes_l like '%law4%'
   or notes_l like '%law5%'
   or notes_l like '%law6%'
order by id
limit 10;
