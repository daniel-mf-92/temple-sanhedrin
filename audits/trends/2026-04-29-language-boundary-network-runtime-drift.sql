-- Historical language-boundary and network-runtime drift audit.
-- Source DB: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Run from temple-sanhedrin:
--   sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-29-language-boundary-network-runtime-drift.sql

.headers on
.mode column

WITH RECURSIVE raw AS (
  SELECT
    id,
    ts,
    agent,
    status,
    task_id,
    replace(replace(replace(coalesce(files_changed, ''), char(10), ','), ';', ','), char(13), ',') || ',' AS rest
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
),
split(id, ts, agent, status, task_id, path, rest) AS (
  SELECT
    id,
    ts,
    agent,
    status,
    task_id,
    trim(substr(rest, 1, instr(rest, ',') - 1)),
    substr(rest, instr(rest, ',') + 1)
  FROM raw
  WHERE rest <> ','
  UNION ALL
  SELECT
    id,
    ts,
    agent,
    status,
    task_id,
    trim(substr(rest, 1, instr(rest, ',') - 1)),
    substr(rest, instr(rest, ',') + 1)
  FROM split
  WHERE rest <> '' AND instr(rest, ',') > 0
),
paths AS (
  SELECT id, ts, agent, status, task_id, lower(path) AS path
  FROM split
  WHERE path <> ''
),
classified AS (
  SELECT
    *,
    CASE
      WHEN agent = 'modernization'
        AND (
          path GLOB 'kernel/*' OR path GLOB 'adam/*' OR path GLOB 'apps/*' OR
          path GLOB 'compiler/*' OR path GLOB '0000boot/*'
        )
        THEN 1
      WHEN agent = 'inference' AND path GLOB 'src/*'
        THEN 1
      ELSE 0
    END AS core_path,
    CASE
      WHEN path GLOB '*.c' OR path GLOB '*.cc' OR path GLOB '*.cpp' OR
           path GLOB '*.rs' OR path GLOB '*.go' OR path GLOB '*.py' OR
           path GLOB '*.js' OR path GLOB '*.ts' OR path GLOB '*/makefile' OR
           path GLOB '*/cmakelists.txt' OR path GLOB '*/cargo.toml' OR
           path IN ('makefile', 'cmakelists.txt', 'cargo.toml')
        THEN 1
      ELSE 0
    END AS foreign_path
  FROM paths
)
SELECT
  agent,
  count(DISTINCT id) AS rows_with_files,
  count(*) AS file_mentions,
  sum(core_path) AS core_file_mentions,
  sum(core_path AND foreign_path) AS core_foreign_file_mentions,
  count(DISTINCT CASE WHEN core_path AND foreign_path THEN id END) AS rows_with_core_foreign_file,
  min(CASE WHEN core_path AND foreign_path THEN ts END) AS first_core_foreign_ts,
  max(CASE WHEN core_path AND foreign_path THEN ts END) AS last_core_foreign_ts
FROM classified
GROUP BY agent
ORDER BY agent;

WITH text_rows AS (
  SELECT
    id,
    ts,
    agent,
    status,
    task_id,
    lower(
      coalesce(task_id, '') || ' ' ||
      coalesce(files_changed, '') || ' ' ||
      coalesce(validation_cmd, '') || ' ' ||
      coalesce(validation_result, '') || ' ' ||
      coalesce(error_msg, '') || ' ' ||
      coalesce(notes, '')
    ) AS body,
    replace(replace(coalesce(files_changed, ''), char(10), ' '), char(13), ' ') AS files_line,
    replace(replace(coalesce(validation_cmd, ''), char(10), ' '), char(13), ' ') AS cmd_line,
    replace(replace(coalesce(validation_result, ''), char(10), ' '), char(13), ' ') AS result_line,
    replace(replace(coalesce(notes, ''), char(10), ' '), char(13), ' ') AS notes_line
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
),
classified AS (
  SELECT
    *,
    CASE
      WHEN body GLOB '*network*' OR body GLOB '*socket*' OR
           body GLOB '*tcp*' OR body GLOB '*udp*' OR
           body GLOB '*dns*' OR body GLOB '*dhcp*' OR
           body GLOB '*http*' OR body GLOB '*tls*' OR
           body GLOB '*curl*' OR body GLOB '*pip install*' OR
           body GLOB '*npm install*' OR body GLOB '*cargo install*'
        THEN 1
      ELSE 0
    END AS network_runtime,
    CASE
      WHEN body GLOB '*air-gap*' OR body GLOB '*airgapped*' OR
           body GLOB '*no network*' OR body GLOB '*no-network*' OR
           body GLOB '*-nic none*' OR body GLOB '*-net none*' OR
           body GLOB '*out-of-scope*'
        THEN 1
      ELSE 0
    END AS guardrail
  FROM text_rows
)
SELECT
  agent,
  count(*) AS rows,
  sum(network_runtime) AS network_runtime_rows,
  sum(network_runtime AND guardrail) AS with_guardrail,
  sum(network_runtime AND NOT guardrail) AS without_guardrail,
  min(CASE WHEN network_runtime THEN ts END) AS first_network_ts,
  max(CASE WHEN network_runtime THEN ts END) AS last_network_ts
FROM classified
GROUP BY agent
ORDER BY agent;

SELECT
  agent,
  count(*) AS rows,
  sum(CASE WHEN lower(coalesce(validation_cmd, '') || ' ' || coalesce(notes, '') || ' ' || coalesce(error_msg, '')) GLOB '*pip install*' THEN 1 ELSE 0 END) AS pip_install_rows,
  sum(CASE WHEN lower(coalesce(validation_cmd, '') || ' ' || coalesce(notes, '') || ' ' || coalesce(error_msg, '')) GLOB '*npm install*' THEN 1 ELSE 0 END) AS npm_install_rows,
  sum(CASE WHEN lower(coalesce(validation_cmd, '') || ' ' || coalesce(notes, '') || ' ' || coalesce(error_msg, '')) GLOB '*cargo install*' THEN 1 ELSE 0 END) AS cargo_install_rows,
  sum(CASE WHEN lower(coalesce(validation_cmd, '') || ' ' || coalesce(notes, '') || ' ' || coalesce(error_msg, '')) GLOB '*curl *' THEN 1 ELSE 0 END) AS curl_rows
FROM iterations
WHERE agent IN ('modernization', 'inference')
GROUP BY agent
ORDER BY agent;

SELECT
  agent,
  count(*) AS python_validation_rows,
  min(ts) AS first_ts,
  max(ts) AS last_ts
FROM iterations
WHERE agent IN ('modernization', 'inference')
  AND lower(coalesce(validation_cmd, '')) GLOB '*python*'
GROUP BY agent
ORDER BY agent;

SELECT
  agent,
  count(*) AS rows,
  min(ts) AS first_ts,
  max(ts) AS last_ts
FROM iterations
GROUP BY agent
ORDER BY agent;
