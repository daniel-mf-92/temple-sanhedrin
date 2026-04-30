-- Historical identifier-compounding drift from temple-central.db files_changed.
-- Run:
--   sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-30-identifier-compounding-files-changed-drift.sql

drop table if exists temp.identifier_compounding_measured;

create temp table identifier_compounding_measured as
with recursive
raw as (
  select
    id,
    ts,
    agent,
    task_id,
    status,
    replace(replace(coalesce(files_changed, ''), char(10), ','), ';', ',') || ',' as rest
  from iterations
  where files_changed is not null
    and trim(files_changed) <> ''
),
file_split(id, ts, agent, task_id, status, path, rest) as (
  select
    id,
    ts,
    agent,
    task_id,
    status,
    trim(substr(rest, 1, instr(rest, ',') - 1)) as path,
    substr(rest, instr(rest, ',') + 1) as rest
  from raw
  union all
  select
    id,
    ts,
    agent,
    task_id,
    status,
    trim(substr(rest, 1, instr(rest, ',') - 1)) as path,
    substr(rest, instr(rest, ',') + 1) as rest
  from file_split
  where rest <> ''
),
paths as (
  select id, ts, agent, task_id, status, path
  from file_split
  where path <> ''
),
segments(id, ts, agent, task_id, status, path, depth, segment, rest) as (
  select
    id,
    ts,
    agent,
    task_id,
    status,
    path,
    1,
    substr(path || '/', 1, instr(path || '/', '/') - 1),
    substr(path || '/', instr(path || '/', '/') + 1)
  from paths
  union all
  select
    id,
    ts,
    agent,
    task_id,
    status,
    path,
    depth + 1,
    substr(rest, 1, instr(rest, '/') - 1),
    substr(rest, instr(rest, '/') + 1)
  from segments
  where rest <> ''
),
basenames as (
  select
    s.id,
    s.ts,
    s.agent,
    s.task_id,
    s.status,
    s.path,
    s.segment as basename
  from segments s
  join (
    select id, path, max(depth) as max_depth
    from segments
    where segment <> ''
    group by id, path
  ) m
    on s.id = m.id
   and s.path = m.path
   and s.depth = m.max_depth
),
measured as (
  select
    id,
    ts,
    substr(ts, 1, 10) as day,
    agent,
    task_id,
    status,
    path,
    basename,
    length(basename) as basename_len,
    (
      length(basename)
      - length(replace(replace(basename, '-', ''), '_', ''))
      + 1
    ) as separator_tokens,
    case
      when length(basename) > 40
        or (
          length(basename)
          - length(replace(replace(basename, '-', ''), '_', ''))
          + 1
        ) > 5
      then 1 else 0
    end as compounds
  from basenames
)
select *
from measured;

select
  agent,
  count(distinct id) as rows_with_files,
  count(*) as changed_paths,
  sum(compounds) as compound_paths,
  count(distinct case when compounds = 1 then id end) as compound_rows,
  round(100.0 * count(distinct case when compounds = 1 then id end) / count(distinct id), 1) as compound_row_pct,
  max(basename_len) as max_basename_len,
  max(separator_tokens) as max_separator_tokens
from identifier_compounding_measured
group by agent
order by compound_rows desc;

select
  agent,
  day,
  count(distinct id) as rows_with_files,
  count(distinct case when compounds = 1 then id end) as compound_rows,
  sum(compounds) as compound_paths
from identifier_compounding_measured
group by agent, day
having compound_rows > 0
order by agent, day;

select
  basename_len,
  separator_tokens,
  id,
  ts,
  agent,
  task_id,
  status,
  path
from identifier_compounding_measured
where compounds = 1
order by basename_len desc, separator_tokens desc, id desc
limit 25;

drop table if exists temp.identifier_compounding_measured;
