-- Read-only support queries for the research reference provenance drift audit.
-- Usage:
--   sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-02-research-refs-drift.sql

.headers on
.mode column

select
  count(*) as research_rows,
  sum(references_urls is null or trim(references_urls) = '') as blank_refs,
  sum(references_urls like '%;%') as semicolon_rows,
  sum(references_urls like '%' || char(10) || '%') as newline_rows,
  sum(references_urls like '%,%') as comma_rows,
  sum(references_urls like '% %') as space_rows
from research;

select
  substr(ts, 1, 10) as day,
  count(*) as rows,
  sum(references_urls is null or trim(references_urls) = '') as blank_refs,
  sum(references_urls like '%;%') as semicolon_rows,
  sum(references_urls like '%' || char(10) || '%') as newline_rows,
  sum(references_urls like '%,%') as comma_rows
from research
group by day
order by day;

select
  substr(ts, 1, 13) || ':00:00' as hour,
  count(*) as rows,
  sum(references_urls is null or trim(references_urls) = '') as blank_refs
from research
group by hour
having rows >= 5
order by blank_refs desc, rows desc
limit 20;

select
  lower(replace(replace(topic, '_', '-'), ' ', '-')) as normalized_topic,
  count(*) as rows,
  sum(references_urls is null or trim(references_urls) = '') as blank_refs,
  sum(references_urls like '%;%') as semicolon_rows,
  sum(references_urls like '%' || char(10) || '%') as newline_rows
from research
group by normalized_topic
order by rows desc, blank_refs desc
limit 20;

select
  id,
  ts,
  topic,
  trigger_task
from research
where references_urls is null or trim(references_urls) = ''
order by id
limit 25;

select
  'aws.amazon.com' as domain,
  sum(references_urls like '%aws.amazon.com%') as rows
from research
union all
select
  'sre.google',
  sum(references_urls like '%sre.google%')
from research
union all
select
  'docs.temporal.io',
  sum(references_urls like '%docs.temporal.io%')
from research
union all
select
  'docs.github.com',
  sum(references_urls like '%docs.github.com%')
from research
union all
select
  'martinfowler.com',
  sum(references_urls like '%martinfowler.com%')
from research
union all
select
  'arxiv.org',
  sum(references_urls like '%arxiv.org%')
from research
order by rows desc;
