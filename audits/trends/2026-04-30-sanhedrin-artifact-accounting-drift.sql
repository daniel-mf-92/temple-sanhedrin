-- Sanhedrin artifact-accounting drift trend audit.
-- Read-only query pack for:
-- /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db

.headers on
.mode column

select
  agent,
  count(*) as total_rows,
  sum(files_changed is null or trim(files_changed) = '') as blank_files_changed,
  sum(lines_added = 0 and lines_removed = 0) as zero_delta_rows,
  round(100.0 * sum(lines_added = 0 and lines_removed = 0) / count(*), 1) as zero_delta_pct,
  sum(duration_sec is null) as null_duration_rows
from iterations
group by agent
order by agent;

select
  status,
  count(*) as total_rows,
  sum(files_changed is not null and trim(files_changed) != '') as nonblank_files_changed,
  sum(lines_added = 0 and lines_removed = 0) as zero_delta_rows,
  round(avg(length(coalesce(notes, ''))), 1) as avg_note_len
from iterations
where agent = 'sanhedrin'
group by status
order by total_rows desc;

select
  task_id,
  status,
  count(*) as rows,
  sum(files_changed is not null and trim(files_changed) != '') as nonblank_files_changed,
  min(length(coalesce(notes, ''))) as min_note_len,
  round(avg(length(coalesce(notes, ''))), 1) as avg_note_len,
  max(length(coalesce(notes, ''))) as max_note_len
from iterations
where agent = 'sanhedrin'
group by task_id, status
having count(*) >= 20
order by rows desc
limit 25;

select
  date(ts) as day,
  count(*) as sanhedrin_rows,
  sum(files_changed is not null and trim(files_changed) != '') as nonblank_files_changed,
  sum(task_id = 'AUDIT') as audit_rows,
  sum(task_id = 'RESEARCH') as research_rows
from iterations
where agent = 'sanhedrin'
  and date(ts) is not null
group by date(ts)
order by day;

select
  count(*) as sanhedrin_rows,
  sum(files_changed is not null and trim(files_changed) != '') as nonblank_files_changed,
  count(distinct nullif(trim(files_changed), '')) as distinct_files_changed,
  sum(length(coalesce(notes, '')) >= 200) as long_notes_200,
  round(avg(length(coalesce(notes, ''))), 1) as avg_note_len,
  max(length(coalesce(notes, ''))) as max_note_len
from iterations
where agent = 'sanhedrin';

select
  files_changed,
  count(*) as rows,
  min(ts) as first_ts,
  max(ts) as last_ts
from iterations
where agent = 'sanhedrin'
  and files_changed is not null
  and trim(files_changed) != ''
group by files_changed
order by rows desc, files_changed
limit 15;
