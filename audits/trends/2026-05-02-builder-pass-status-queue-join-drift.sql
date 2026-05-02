-- Historical drift audit: builder pass-status collapse and queue join loss.
-- Source DB: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db

.headers on
.mode column

select
  agent,
  count(*) as rows,
  sum(case when status = 'pass' then 1 else 0 end) as pass_rows,
  sum(case when status <> 'pass' then 1 else 0 end) as non_pass_rows,
  sum(case
        when lower(validation_result) glob '*fail*'
          or lower(validation_result) glob '*error*'
          or lower(validation_result) glob '*blocked*'
          or lower(validation_result) glob '*timeout*'
        then 1 else 0
      end) as result_negative_words,
  sum(case
        when lower(notes) glob '*fail*'
          or lower(notes) glob '*error*'
          or lower(notes) glob '*blocked*'
          or lower(notes) glob '*timeout*'
        then 1 else 0
      end) as notes_negative_words,
  sum(case when validation_result like '%skip%' or validation_result like '%skipped%' then 1 else 0 end) as result_skip_words,
  sum(case when notes like '%skip%' or notes like '%skipped%' then 1 else 0 end) as notes_skip_words
from iterations
where agent in ('modernization', 'inference')
group by agent
order by agent;

select
  substr(ts, 1, 10) as day,
  agent,
  count(*) as rows,
  count(distinct task_id) as distinct_tasks,
  round(1.0 * count(*) / count(distinct task_id), 2) as rows_per_task,
  sum(case when status <> 'pass' then 1 else 0 end) as non_pass_rows
from iterations
where agent in ('modernization', 'inference')
group by day, agent
order by day, agent;

select
  agent,
  count(distinct task_id) as distinct_tasks,
  count(*) as rows,
  round(1.0 * count(*) / count(distinct task_id), 2) as rows_per_task,
  sum(case when task_id in (select id from queue) then 1 else 0 end) as rows_joining_queue
from iterations
where agent in ('modernization', 'inference')
group by agent
order by agent;

select
  i.agent,
  i.task_id,
  count(*) as rows,
  min(i.ts) as first_ts,
  max(i.ts) as last_ts,
  q.status as queue_status,
  q.attempt_count,
  substr(q.description, 1, 72) as queue_description
from iterations i
left join queue q on q.id = i.task_id
where i.agent in ('modernization', 'inference')
group by i.agent, i.task_id
having rows >= 3
order by rows desc, i.agent, i.task_id
limit 50;

select count(*) as queue_rows from queue;
