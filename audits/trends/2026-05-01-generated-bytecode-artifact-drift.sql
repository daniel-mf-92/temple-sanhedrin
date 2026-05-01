-- Historical generated-bytecode artifact drift audit.
-- Run read-only:
-- sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-01-generated-bytecode-artifact-drift.sql

.headers on
.mode column

WITH builder_rows AS (
  SELECT *
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
),
generated_rows AS (
  SELECT *
  FROM builder_rows
  WHERE lower(coalesce(files_changed, '')) LIKE '%.pyc%'
     OR lower(coalesce(files_changed, '')) LIKE '%__pycache__%'
     OR lower(coalesce(files_changed, '')) LIKE '%.pytest_cache%'
     OR lower(coalesce(files_changed, '')) LIKE '%/build/%'
     OR lower(coalesce(files_changed, '')) LIKE '%/dist/%'
)
SELECT
  agent,
  count(*) AS rows,
  sum(CASE WHEN lower(coalesce(files_changed, '')) LIKE '%.pyc%' THEN 1 ELSE 0 END) AS pyc_rows,
  sum(CASE WHEN lower(coalesce(files_changed, '')) LIKE '%__pycache__%' THEN 1 ELSE 0 END) AS pycache_rows,
  sum(CASE WHEN lower(coalesce(files_changed, '')) LIKE '%.pytest_cache%' THEN 1 ELSE 0 END) AS pytest_cache_rows,
  sum(CASE WHEN lower(coalesce(files_changed, '')) LIKE '%/build/%' THEN 1 ELSE 0 END) AS build_rows,
  sum(CASE WHEN lower(coalesce(files_changed, '')) LIKE '%/dist/%' THEN 1 ELSE 0 END) AS dist_rows
FROM builder_rows
GROUP BY agent
ORDER BY agent;

WITH builder_rows AS (
  SELECT *
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
),
generated_rows AS (
  SELECT *
  FROM builder_rows
  WHERE lower(coalesce(files_changed, '')) LIKE '%.pyc%'
     OR lower(coalesce(files_changed, '')) LIKE '%__pycache__%'
     OR lower(coalesce(files_changed, '')) LIKE '%.pytest_cache%'
     OR lower(coalesce(files_changed, '')) LIKE '%/build/%'
     OR lower(coalesce(files_changed, '')) LIKE '%/dist/%'
)
SELECT
  agent,
  status,
  count(*) AS generated_rows
FROM generated_rows
GROUP BY agent, status
ORDER BY agent, status;

WITH builder_rows AS (
  SELECT *
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
),
generated_rows AS (
  SELECT *
  FROM builder_rows
  WHERE lower(coalesce(files_changed, '')) LIKE '%.pyc%'
     OR lower(coalesce(files_changed, '')) LIKE '%__pycache__%'
     OR lower(coalesce(files_changed, '')) LIKE '%.pytest_cache%'
     OR lower(coalesce(files_changed, '')) LIKE '%/build/%'
     OR lower(coalesce(files_changed, '')) LIKE '%/dist/%'
)
SELECT
  substr(ts, 1, 10) AS day,
  agent,
  count(*) AS generated_rows
FROM generated_rows
GROUP BY day, agent
ORDER BY day, agent;

WITH builder_rows AS (
  SELECT *
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
),
generated_rows AS (
  SELECT *
  FROM builder_rows
  WHERE lower(coalesce(files_changed, '')) LIKE '%.pyc%'
     OR lower(coalesce(files_changed, '')) LIKE '%__pycache__%'
     OR lower(coalesce(files_changed, '')) LIKE '%.pytest_cache%'
     OR lower(coalesce(files_changed, '')) LIKE '%/build/%'
     OR lower(coalesce(files_changed, '')) LIKE '%/dist/%'
)
SELECT
  id,
  ts,
  agent,
  task_id,
  lines_added,
  lines_removed,
  duration_sec,
  validation_result
FROM generated_rows
ORDER BY id;

WITH builder_rows AS (
  SELECT *
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
),
generated_rows AS (
  SELECT *
  FROM builder_rows
  WHERE lower(coalesce(files_changed, '')) LIKE '%.pyc%'
     OR lower(coalesce(files_changed, '')) LIKE '%__pycache__%'
     OR lower(coalesce(files_changed, '')) LIKE '%.pytest_cache%'
     OR lower(coalesce(files_changed, '')) LIKE '%/build/%'
     OR lower(coalesce(files_changed, '')) LIKE '%/dist/%'
)
SELECT
  id,
  task_id,
  files_changed
FROM generated_rows
ORDER BY id;

WITH builder_rows AS (
  SELECT *
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
)
SELECT
  agent,
  count(*) AS rows,
  sum(CASE WHEN lower(coalesce(files_changed, '')) LIKE '%.hc%' THEN 1 ELSE 0 END) AS hc_rows,
  sum(CASE WHEN lower(coalesce(files_changed, '')) LIKE '%.py%' THEN 1 ELSE 0 END) AS py_rows,
  sum(CASE WHEN lower(coalesce(files_changed, '')) LIKE '%.pyc%' THEN 1 ELSE 0 END) AS pyc_rows
FROM builder_rows
GROUP BY agent
ORDER BY agent;
