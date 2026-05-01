-- Historical trend audit: temple-central timestamp format drift.
-- Read-only query pack for:
-- /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db

.headers on
.mode column

select
  agent,
  count(*) as total_rows,
  sum(case when ts glob '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T*' then 1 else 0 end) as iso_t_rows,
  sum(case when ts glob '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:*' then 1 else 0 end) as iso_space_rows,
  sum(case when ts glob '[0-9]*' and ts not glob '[0-9][0-9][0-9][0-9]-*' then 1 else 0 end) as epoch_rows,
  min(ts) as min_ts_lexical,
  max(ts) as max_ts_lexical
from iterations
group by agent
order by agent;

select
  count(*) as total_rows,
  sum(case when ts glob '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T*' then 1 else 0 end) as iso_t_rows,
  sum(case when ts glob '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:*' then 1 else 0 end) as iso_space_rows,
  sum(case when ts glob '[0-9]*' and ts not glob '[0-9][0-9][0-9][0-9]-*' then 1 else 0 end) as epoch_rows
from iterations;

select
  id,
  ts,
  datetime(cast(ts as integer), 'unixepoch') as epoch_as_utc,
  agent,
  status,
  task_id
from iterations
where ts glob '[0-9]*'
  and ts not glob '[0-9][0-9][0-9][0-9]-*'
order by id;

select
  id,
  ts,
  agent,
  status,
  task_id
from iterations
where ts glob '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:*'
order by id;

with normalized as (
  select
    id,
    agent,
    status,
    task_id,
    ts,
    case
      when ts glob '[0-9][0-9][0-9][0-9]-*' then cast(strftime('%s', ts) as integer)
      else cast(ts as integer)
    end as epoch
  from iterations
),
ordered_rows as (
  select
    id,
    agent,
    status,
    task_id,
    ts,
    epoch,
    lag(epoch) over (order by id) as previous_epoch
  from normalized
)
select
  count(*) as rows_moving_backwards_by_id
from ordered_rows
where previous_epoch is not null
  and epoch < previous_epoch;

select
  task_id,
  status,
  count(*) as rows,
  min(ts) as min_ts_lexical,
  max(ts) as max_ts_lexical
from iterations
where agent = 'sanhedrin'
group by task_id, status
order by rows desc, task_id, status
limit 20;

select
  agent,
  substr(ts, 1, 10) as naive_day_bucket,
  count(*) as rows
from iterations
group by agent, naive_day_bucket
order by agent, naive_day_bucket;
