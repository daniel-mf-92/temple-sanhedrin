-- Historical observability split-brain audit.
-- Read-only SQL portion for temple-central.db; companion report also counts
-- post-DB final-summary files from builder automation/logs directories.

.headers on
.mode column

select
  count(*) as iteration_rows,
  min(ts) as first_ts,
  max(ts) as last_ts
from iterations;

select
  agent,
  count(*) as db_rows,
  max(ts) as db_last_ts
from iterations
group by agent
order by agent;

select
  agent,
  status,
  count(*) as rows
from iterations
group by agent, status
order by agent, status;

select
  agent,
  status,
  count(*) as blocked_rows
from iterations
where status = 'blocked'
group by agent, status
order by agent;

with agents(agent) as (
  values ('inference'), ('modernization'), ('sanhedrin')
)
select
  agents.agent,
  count(iterations.id) as rows_after_builder_final_log_start
from agents
left join iterations
  on iterations.agent = agents.agent
 and iterations.ts >= '2026-04-27T15:50:31'
group by agents.agent
order by agents.agent;

select
  'queue' as table_name,
  count(*) as rows
from queue
union all
select
  'violations' as table_name,
  count(*) as rows
from violations
union all
select
  'research' as table_name,
  count(*) as rows
from research;
