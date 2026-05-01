-- Historical files_changed join-drift audit, read-only against temple-central.db.
-- Source DB: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Usage:
--   sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-01-files-changed-current-head-join-drift.sql

SELECT agent,
       count(*) AS rows_with_files_changed,
       min(ts) AS first_ts,
       max(ts) AS last_ts
FROM iterations
WHERE agent IN ('modernization','inference')
  AND files_changed IS NOT NULL
  AND trim(files_changed) <> ''
GROUP BY agent
ORDER BY agent;

SELECT agent,
       files_changed,
       count(*) AS rows
FROM iterations
WHERE agent IN ('modernization','inference')
  AND files_changed IN ('1', '(superseded)')
GROUP BY agent, files_changed
ORDER BY agent, files_changed;

SELECT id, ts, agent, task_id, status, files_changed
FROM iterations
WHERE agent IN ('modernization','inference')
  AND files_changed IN ('1', '(superseded)')
ORDER BY id;

SELECT agent,
       sum(CASE WHEN files_changed LIKE '%src/%' THEN 1 ELSE 0 END) AS rows_naming_src,
       sum(CASE WHEN files_changed LIKE '%Kernel/%' THEN 1 ELSE 0 END) AS rows_naming_kernel,
       sum(CASE WHEN files_changed LIKE '%automation/%' THEN 1 ELSE 0 END) AS rows_naming_automation,
       sum(CASE WHEN files_changed LIKE '%tests/%' THEN 1 ELSE 0 END) AS rows_naming_tests
FROM iterations
WHERE agent IN ('modernization','inference')
  AND files_changed IS NOT NULL
  AND trim(files_changed) <> ''
GROUP BY agent
ORDER BY agent;
