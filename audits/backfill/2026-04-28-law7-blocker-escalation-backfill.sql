-- Law 7 Blocker Escalation compliance backfill.
-- Historical/read-only analysis against temple-central.db.
-- Source DB: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Run from temple-sanhedrin:
--   sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/backfill/2026-04-28-law7-blocker-escalation-backfill.sql

.headers on
.mode column

select
  agent,
  count(*) as total_rows,
  min(ts) as first_ts,
  max(ts) as last_ts,
  sum(status='pass') as pass_rows,
  sum(status='fail') as fail_rows,
  sum(status='blocked') as blocked_rows,
  sum(status='skip') as skip_rows
from iterations
group by agent
order by agent;

select
  count(*) as non_iso_iteration_timestamps,
  min(id) as first_id,
  max(id) as last_id,
  min(ts) as min_ts,
  max(ts) as max_ts
from iterations
where ts not glob '????-??-??T??:??:??*';

with classified as (
  select
    id,
    ts,
    agent,
    task_id,
    status,
    case
      when coalesce(notes,'') like '%MARTA_GOOGLE_CLIENT_ID%'
        or coalesce(notes,'') like '%MARTA_GOOGLE_CLIENT_SECRET%'
        then 'missing MARTA Google MCP credentials'
      when coalesce(notes,'') like '%readonly database%'
        or coalesce(error_msg,'') like '%readonly database%'
        or coalesce(validation_result,'') like '%readonly database%'
        then 'readonly database'
      when coalesce(notes,'') like '%command not found%'
        or coalesce(error_msg,'') like '%command not found%'
        or coalesce(validation_result,'') like '%command not found%'
        then 'command not found'
      when coalesce(notes,'') like '%no such column%'
        or coalesce(error_msg,'') like '%no such column%'
        or coalesce(validation_result,'') like '%no such column%'
        then 'no such column'
      when coalesce(notes,'') like '%ssh/auth timeout%'
        or coalesce(error_msg,'') like '%ssh/auth timeout%'
        or coalesce(validation_result,'') like '%ssh/auth timeout%'
        then 'ssh/auth timeout'
      when coalesce(notes,'') like '%24308638070%'
        then 'TempleOS CI run 24308638070 failed'
      else substr(coalesce(nullif(error_msg,''), nullif(validation_result,''), nullif(notes,''), status),1,80)
    end as blocker_key
  from iterations
  where status in ('fail','blocked','skip')
),
ordered_failure_stream as (
  select
    *,
    case
      when lag(blocker_key) over (partition by agent order by id) = blocker_key then 0
      else 1
    end as new_streak
  from classified
),
streaked_failure_stream as (
  select
    *,
    sum(new_streak) over (partition by agent order by id rows unbounded preceding) as streak_id
  from ordered_failure_stream
),
streaks as (
  select
    agent,
    blocker_key,
    streak_id,
    count(*) as n,
    min(ts) as first_ts,
    max(ts) as last_ts
  from streaked_failure_stream
  group by agent, blocker_key, streak_id
)
select
  agent,
  blocker_key,
  max(n) as max_consecutive_nonpass_rows,
  min(first_ts) as first_seen,
  max(last_ts) as last_seen,
  count(*) as streaks_at_or_above_three
from streaks
where n >= 3
group by agent, blocker_key
order by max_consecutive_nonpass_rows desc, blocker_key;

with rows as (
  select
    id,
    ts,
    agent,
    task_id,
    status,
    case
      when status in ('fail','blocked','skip')
        and (
          coalesce(notes,'') like '%MARTA_GOOGLE_CLIENT_ID%'
          or coalesce(notes,'') like '%MARTA_GOOGLE_CLIENT_SECRET%'
        )
        then 'missing MARTA Google MCP credentials'
      when status in ('fail','blocked','skip')
        and (
          coalesce(notes,'') like '%24308638070%'
        )
        then 'TempleOS CI run 24308638070 failed'
      when status in ('fail','blocked','skip')
        and (
          coalesce(notes,'') like '%readonly database%'
          or coalesce(error_msg,'') like '%readonly database%'
          or coalesce(validation_result,'') like '%readonly database%'
        )
        then 'readonly database'
      when status in ('fail','blocked','skip')
        and (
          coalesce(notes,'') like '%command not found%'
          or coalesce(error_msg,'') like '%command not found%'
          or coalesce(validation_result,'') like '%command not found%'
        )
        then 'command not found'
      when status in ('fail','blocked','skip')
        then substr(coalesce(nullif(error_msg,''), nullif(validation_result,''), nullif(notes,''), status),1,80)
      else 'PASS_OR_OTHER'
    end as blocker_key
  from iterations
),
ordered_all_rows as (
  select
    *,
    case
      when lag(blocker_key) over (partition by agent order by id) = blocker_key then 0
      else 1
    end as new_streak
  from rows
),
streaked_all_rows as (
  select
    *,
    sum(new_streak) over (partition by agent order by id rows unbounded preceding) as streak_id
  from ordered_all_rows
),
all_row_streaks as (
  select
    agent,
    blocker_key,
    streak_id,
    count(*) as n,
    min(ts) as first_ts,
    max(ts) as last_ts
  from streaked_all_rows
  group by agent, blocker_key, streak_id
)
select
  agent,
  blocker_key,
  max(n) as max_consecutive_all_iteration_rows,
  min(first_ts) as first_seen,
  max(last_ts) as last_seen,
  count(*) as streaks_at_or_above_three
from all_row_streaks
where blocker_key <> 'PASS_OR_OTHER'
  and n >= 3
group by agent, blocker_key
order by max_consecutive_all_iteration_rows desc, blocker_key;

select
  case
    when coalesce(notes,'') like '%MARTA_GOOGLE_CLIENT_ID%'
      or coalesce(notes,'') like '%MARTA_GOOGLE_CLIENT_SECRET%'
      then 'missing MARTA Google MCP credentials'
    when coalesce(notes,'') like '%24308638070%'
      then 'TempleOS CI run 24308638070 failed'
    when coalesce(notes,'') like '%no such column%'
      or coalesce(error_msg,'') like '%no such column%'
      or coalesce(validation_result,'') like '%no such column%'
      then 'no such column'
    when coalesce(notes,'') like '%readonly database%'
      or coalesce(error_msg,'') like '%readonly database%'
      or coalesce(validation_result,'') like '%readonly database%'
      then 'readonly database'
    else 'other'
  end as blocker_key,
  count(*) as rows,
  min(ts) as first_ts,
  max(ts) as last_ts
from iterations
where status in ('fail','blocked','skip')
group by blocker_key
order by rows desc, blocker_key;
