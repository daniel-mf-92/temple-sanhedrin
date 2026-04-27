-- Historical blocker-persistence trend audit, read-only against temple-central.db.
-- Source DB: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Run from temple-sanhedrin:
--   sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-28-temple-central-blocker-persistence.sql

.headers on
.mode column

select
  agent,
  count(*) as total,
  sum(status='pass') as pass,
  sum(status='fail') as fail,
  sum(status='blocked') as blocked,
  sum(status='skip') as skip,
  min(ts) as first_ts,
  max(ts) as last_ts
from iterations
group by agent
order by agent;

select
  substr(ts,1,10) as day,
  status,
  count(*) as n
from iterations
where agent='sanhedrin'
  and status in ('fail','blocked','skip')
group by day, status
order by day, status;

select
  task_id,
  status,
  count(*) as n,
  min(ts) as first_ts,
  max(ts) as last_ts
from iterations
where agent='sanhedrin'
  and status in ('fail','blocked')
group by task_id, status
order by n desc, task_id;

with classified as (
  select
    id,
    ts,
    status,
    task_id,
    case
      when coalesce(notes,'') like '%MARTA_GOOGLE_CLIENT_ID%'
        or coalesce(notes,'') like '%MARTA_GOOGLE_CLIENT_SECRET%'
        then 'missing Google MCP credentials'
      when coalesce(notes,'') like '%24308638070%'
        then 'TempleOS CI run 24308638070 failed'
      when coalesce(notes,'') like '%gh run list%'
        and (coalesce(notes,'') like '%no runs%' or coalesce(notes,'') like '%no recent runs%')
        then 'GitHub Actions run list empty'
      when coalesce(notes,'') like '%no such column%'
        then 'VM sqlite schema mismatch'
      when coalesce(notes,'') like '%ssh/auth timeout%'
        then 'Azure VM ssh/auth timeout'
      when coalesce(notes,'') like '%latest5 non-pass=-1%'
        or coalesce(notes,'') like '%fail_count=-1%'
        then 'VM compile status unknown/non-pass sentinel'
      when coalesce(notes,'') like '%Law5%'
        and (
          coalesce(notes,'') like '%HC_SH=0%'
          or coalesce(notes,'') like '%0 .HC%'
          or coalesce(notes,'') like '%last5_HC_SH=0%'
        )
        then 'Law5 zero HolyC/source recent commits'
      else task_id || ' ' || status || ' other'
    end as blocker_key
  from iterations
  where agent='sanhedrin'
    and status in ('fail','blocked','skip')
)
select
  blocker_key,
  status,
  count(*) as n,
  min(ts) as first_ts,
  max(ts) as last_ts
from classified
group by blocker_key, status
order by n desc, blocker_key, status
limit 30;

with classified as (
  select
    id,
    ts,
    case
      when coalesce(notes,'') like '%MARTA_GOOGLE_CLIENT_ID%'
        or coalesce(notes,'') like '%MARTA_GOOGLE_CLIENT_SECRET%'
        then 'missing Google MCP credentials'
      when coalesce(notes,'') like '%24308638070%'
        then 'TempleOS CI run 24308638070 failed'
      when coalesce(notes,'') like '%gh run list%'
        and (coalesce(notes,'') like '%no runs%' or coalesce(notes,'') like '%no recent runs%')
        then 'GitHub Actions run list empty'
      when coalesce(notes,'') like '%no such column%'
        then 'VM sqlite schema mismatch'
      when coalesce(notes,'') like '%ssh/auth timeout%'
        then 'Azure VM ssh/auth timeout'
      when coalesce(notes,'') like '%latest5 non-pass=-1%'
        or coalesce(notes,'') like '%fail_count=-1%'
        then 'VM compile status unknown/non-pass sentinel'
      when coalesce(notes,'') like '%Law5%'
        and (
          coalesce(notes,'') like '%HC_SH=0%'
          or coalesce(notes,'') like '%0 .HC%'
          or coalesce(notes,'') like '%last5_HC_SH=0%'
        )
        then 'Law5 zero HolyC/source recent commits'
      else task_id || ' ' || status || ' other'
    end as blocker_key
  from iterations
  where agent='sanhedrin'
    and status in ('fail','blocked','skip')
),
ordered as (
  select
    *,
    case
      when lag(blocker_key) over (order by id) = blocker_key then 0
      else 1
    end as new_streak
  from classified
),
streaked as (
  select
    *,
    sum(new_streak) over (order by id rows unbounded preceding) as streak_id
  from ordered
),
streaks as (
  select
    blocker_key,
    streak_id,
    count(*) as n,
    min(ts) as first_ts,
    max(ts) as last_ts
  from streaked
  group by blocker_key, streak_id
)
select
  blocker_key,
  max(n) as max_consecutive_rows,
  first_ts,
  last_ts
from streaks
group by blocker_key
order by max_consecutive_rows desc, blocker_key
limit 20;

select
  count(*) as violation_rows,
  sum(resolved=0) as unresolved_rows,
  sum(resolved=1) as resolved_rows
from violations;

select
  count(*) as non_iso_iteration_timestamps
from iterations
where ts not glob '????-??-??T??:??:??*';
