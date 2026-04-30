-- Historical validation command compounding drift queries.
-- Database: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Scope: read-only trend evidence from builder iteration rows.

.headers on
.mode column

with builder as (
  select
    id,
    ts,
    agent,
    task_id,
    validation_cmd,
    length(coalesce(validation_cmd, '')) as cmd_len,
    ((length(coalesce(validation_cmd, '')) - length(replace(coalesce(validation_cmd, ''), '&&', ''))) / 2) as and_count,
    (length(coalesce(validation_cmd, '')) - length(replace(coalesce(validation_cmd, ''), ';', ''))) as semicolon_count
  from iterations
  where agent in ('inference', 'modernization')
)
select
  'command_length_summary' as section,
  agent,
  count(*) as rows,
  max(cmd_len) as max_cmd_len,
  round(avg(cmd_len), 1) as avg_cmd_len,
  sum(cmd_len >= 500) as rows_ge_500,
  sum(cmd_len >= 1000) as rows_ge_1000,
  max(and_count) as max_and_chains,
  sum(and_count >= 5) as rows_and_ge_5,
  max(semicolon_count) as max_semicolons,
  sum(semicolon_count >= 5) as rows_semicolon_ge_5
from builder
group by agent;

with builder as (
  select
    agent,
    validation_cmd,
    count(*) as repeat_count,
    min(ts) as first_ts,
    max(ts) as last_ts
  from iterations
  where agent in ('inference', 'modernization')
  group by agent, validation_cmd
  having count(*) > 1
)
select
  'exact_repeated_commands' as section,
  agent,
  count(*) as exact_repeated_cmds,
  sum(repeat_count) as rows_in_repeated_cmds,
  max(repeat_count) as max_repeat_count
from builder
group by agent;

with builder as (
  select
    agent,
    date(case
      when ts glob '[0-9][0-9][0-9][0-9]-*' then ts
      else datetime(cast(ts as integer), 'unixepoch')
    end) as day,
    length(coalesce(validation_cmd, '')) as cmd_len,
    ((length(coalesce(validation_cmd, '')) - length(replace(coalesce(validation_cmd, ''), '&&', ''))) / 2) as and_count
  from iterations
  where agent in ('inference', 'modernization')
)
select
  'daily_long_or_chained_commands' as section,
  agent,
  day,
  count(*) as rows,
  round(avg(cmd_len), 1) as avg_cmd_len,
  max(cmd_len) as max_cmd_len,
  sum(cmd_len >= 500) as rows_ge_500,
  sum(and_count >= 5) as rows_and_ge_5
from builder
group by agent, day
having rows_ge_500 > 0 or rows_and_ge_5 > 0
order by day, agent;

select
  'longest_commands' as section,
  agent,
  id,
  ts,
  task_id,
  length(coalesce(validation_cmd, '')) as cmd_len,
  substr(validation_cmd, 1, 240) as cmd_prefix
from iterations
where agent in ('inference', 'modernization')
order by cmd_len desc
limit 12;
