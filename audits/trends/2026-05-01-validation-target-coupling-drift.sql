-- Historical changed-file / validation-target coupling drift audit.
-- Source DB: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
-- Run with:
--   sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-01-validation-target-coupling-drift.sql

.headers on
.mode column

WITH RECURSIVE raw AS (
  SELECT
    id, ts, agent, task_id, status,
    replace(coalesce(files_changed, ''), ';', ',') || ',' AS rest,
    validation_cmd, validation_result, notes
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
), split AS (
  SELECT
    id, ts, agent, task_id, status,
    trim(substr(rest, 1, instr(rest, ',') - 1)) AS path,
    substr(rest, instr(rest, ',') + 1) AS rest,
    validation_cmd, validation_result, notes
  FROM raw
  WHERE rest <> ''
  UNION ALL
  SELECT
    id, ts, agent, task_id, status,
    trim(substr(rest, 1, instr(rest, ',') - 1)) AS path,
    substr(rest, instr(rest, ',') + 1) AS rest,
    validation_cmd, validation_result, notes
  FROM split
  WHERE rest <> ''
), paths AS (
  SELECT
    id, ts, agent, task_id, status, path,
    lower(path) AS lpath,
    lower(coalesce(validation_cmd, '')) AS lcmd,
    validation_cmd, validation_result, notes
  FROM split
  WHERE path <> ''
), row_flags AS (
  SELECT
    id, ts, agent, task_id, status, validation_cmd, validation_result, notes,
    group_concat(path, ', ') AS files,
    group_concat(
      CASE
        WHEN lpath LIKE 'tests/%'
          OR lpath LIKE '%/tests/%'
          OR lpath LIKE 'test_%'
          OR lpath LIKE '%test_%.py'
        THEN path
      END,
      ', '
    ) AS test_files,
    group_concat(
      CASE
        WHEN lpath LIKE 'src/%.hc'
          OR lpath LIKE 'kernel/%.hc'
          OR lpath LIKE 'adam/%.hc'
          OR lpath LIKE 'apps/%.hc'
          OR lpath LIKE 'compiler/%.hc'
        THEN path
      END,
      ', '
    ) AS core_hc_files,
    sum(
      CASE
        WHEN lpath LIKE 'tests/%'
          OR lpath LIKE '%/tests/%'
          OR lpath LIKE 'test_%'
          OR lpath LIKE '%test_%.py'
        THEN 1 ELSE 0
      END
    ) AS test_path_count,
    sum(
      CASE
        WHEN (lpath LIKE 'tests/%'
          OR lpath LIKE '%/tests/%'
          OR lpath LIKE 'test_%'
          OR lpath LIKE '%test_%.py')
          AND instr(lcmd, lpath) = 0
        THEN 1 ELSE 0
      END
    ) AS test_paths_not_in_cmd,
    sum(
      CASE
        WHEN lpath LIKE 'src/%.hc'
          OR lpath LIKE 'kernel/%.hc'
          OR lpath LIKE 'adam/%.hc'
          OR lpath LIKE 'apps/%.hc'
          OR lpath LIKE 'compiler/%.hc'
        THEN 1 ELSE 0
      END
    ) AS core_hc_path_count,
    sum(CASE WHEN lpath LIKE 'automation/%' THEN 1 ELSE 0 END) AS automation_path_count,
    max(CASE WHEN lcmd LIKE '%pytest%' THEN 1 ELSE 0 END) AS cmd_mentions_pytest,
    max(CASE WHEN lcmd LIKE '%qemu%' THEN 1 ELSE 0 END) AS cmd_mentions_qemu,
    max(CASE WHEN lcmd LIKE '%bash -n%' THEN 1 ELSE 0 END) AS cmd_mentions_shell_syntax,
    max(CASE WHEN lcmd LIKE '%...%' THEN 1 ELSE 0 END) AS cmd_has_ellipsis
  FROM paths
  GROUP BY id
)
SELECT
  'overall_changed_file_coupling' AS section,
  agent,
  count(*) AS rows,
  sum(test_path_count > 0) AS rows_with_tests,
  sum(test_path_count > 0 AND test_paths_not_in_cmd > 0) AS rows_with_test_target_elision,
  sum(core_hc_path_count > 0) AS rows_with_core_hc,
  sum(core_hc_path_count > 0 AND test_path_count = 0) AS core_rows_without_test_paths,
  sum(core_hc_path_count > 0 AND test_path_count = 0 AND automation_path_count = 0) AS core_rows_without_test_or_automation_paths,
  sum(cmd_has_ellipsis) AS rows_with_command_ellipsis
FROM row_flags
GROUP BY agent
ORDER BY agent;

WITH RECURSIVE raw AS (
  SELECT id, ts, agent, task_id, status, replace(coalesce(files_changed, ''), ';', ',') || ',' AS rest, validation_cmd, validation_result, notes
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
), split AS (
  SELECT id, ts, agent, task_id, status, trim(substr(rest, 1, instr(rest, ',') - 1)) AS path, substr(rest, instr(rest, ',') + 1) AS rest, validation_cmd, validation_result, notes
  FROM raw WHERE rest <> ''
  UNION ALL
  SELECT id, ts, agent, task_id, status, trim(substr(rest, 1, instr(rest, ',') - 1)), substr(rest, instr(rest, ',') + 1), validation_cmd, validation_result, notes
  FROM split WHERE rest <> ''
), paths AS (
  SELECT *, lower(path) AS lpath, lower(coalesce(validation_cmd, '')) AS lcmd FROM split WHERE path <> ''
), row_flags AS (
  SELECT
    id, ts, agent, task_id, status, validation_cmd,
    group_concat(CASE WHEN lpath LIKE 'tests/%' OR lpath LIKE '%/tests/%' OR lpath LIKE 'test_%' OR lpath LIKE '%test_%.py' THEN path END, ', ') AS test_files,
    sum(CASE WHEN lpath LIKE 'tests/%' OR lpath LIKE '%/tests/%' OR lpath LIKE 'test_%' OR lpath LIKE '%test_%.py' THEN 1 ELSE 0 END) AS test_path_count,
    sum(CASE WHEN (lpath LIKE 'tests/%' OR lpath LIKE '%/tests/%' OR lpath LIKE 'test_%' OR lpath LIKE '%test_%.py') AND instr(lcmd, lpath) = 0 THEN 1 ELSE 0 END) AS test_paths_not_in_cmd,
    max(CASE WHEN lcmd LIKE '%...%' THEN 1 ELSE 0 END) AS cmd_has_ellipsis,
    max(CASE WHEN lcmd LIKE '%pytest%' THEN 1 ELSE 0 END) AS cmd_mentions_pytest
  FROM paths GROUP BY id
)
SELECT
  'test_target_elision_examples' AS section,
  id, ts, agent, task_id, test_files,
  cmd_mentions_pytest, cmd_has_ellipsis,
  substr(validation_cmd, 1, 180) AS validation_cmd
FROM row_flags
WHERE test_path_count > 0
  AND test_paths_not_in_cmd > 0
ORDER BY id DESC
LIMIT 20;

WITH RECURSIVE raw AS (
  SELECT id, ts, agent, task_id, status, replace(coalesce(files_changed, ''), ';', ',') || ',' AS rest, validation_cmd, validation_result, notes
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
), split AS (
  SELECT id, ts, agent, task_id, status, trim(substr(rest, 1, instr(rest, ',') - 1)) AS path, substr(rest, instr(rest, ',') + 1) AS rest, validation_cmd, validation_result, notes
  FROM raw WHERE rest <> ''
  UNION ALL
  SELECT id, ts, agent, task_id, status, trim(substr(rest, 1, instr(rest, ',') - 1)), substr(rest, instr(rest, ',') + 1), validation_cmd, validation_result, notes
  FROM split WHERE rest <> ''
), paths AS (
  SELECT *, lower(path) AS lpath, lower(coalesce(validation_cmd, '')) AS lcmd FROM split WHERE path <> ''
), row_flags AS (
  SELECT
    id, ts, agent, task_id, status, validation_cmd, validation_result, notes,
    group_concat(CASE WHEN lpath LIKE 'src/%.hc' OR lpath LIKE 'kernel/%.hc' OR lpath LIKE 'adam/%.hc' OR lpath LIKE 'apps/%.hc' OR lpath LIKE 'compiler/%.hc' THEN path END, ', ') AS core_hc_files,
    sum(CASE WHEN lpath LIKE 'tests/%' OR lpath LIKE '%/tests/%' OR lpath LIKE 'test_%' OR lpath LIKE '%test_%.py' THEN 1 ELSE 0 END) AS test_path_count,
    sum(CASE WHEN lpath LIKE 'src/%.hc' OR lpath LIKE 'kernel/%.hc' OR lpath LIKE 'adam/%.hc' OR lpath LIKE 'apps/%.hc' OR lpath LIKE 'compiler/%.hc' THEN 1 ELSE 0 END) AS core_hc_path_count,
    sum(CASE WHEN lpath LIKE 'automation/%' THEN 1 ELSE 0 END) AS automation_path_count,
    max(CASE WHEN lcmd LIKE '%qemu%' THEN 1 ELSE 0 END) AS cmd_mentions_qemu,
    max(CASE WHEN lcmd LIKE '%bash -n%' THEN 1 ELSE 0 END) AS cmd_mentions_shell_syntax,
    max(CASE WHEN lcmd LIKE '%...%' THEN 1 ELSE 0 END) AS cmd_has_ellipsis
  FROM paths GROUP BY id
)
SELECT
  'latest_core_rows_without_test_paths' AS section,
  id, ts, agent, task_id, core_hc_files,
  automation_path_count, cmd_mentions_qemu, cmd_mentions_shell_syntax, cmd_has_ellipsis,
  substr(validation_cmd, 1, 180) AS validation_cmd
FROM row_flags
WHERE core_hc_path_count > 0
  AND test_path_count = 0
ORDER BY id DESC
LIMIT 20;

WITH RECURSIVE raw AS (
  SELECT id, ts, agent, task_id, status, replace(coalesce(files_changed, ''), ';', ',') || ',' AS rest, validation_cmd, validation_result, notes
  FROM iterations
  WHERE agent IN ('modernization', 'inference')
), split AS (
  SELECT id, ts, agent, task_id, status, trim(substr(rest, 1, instr(rest, ',') - 1)) AS path, substr(rest, instr(rest, ',') + 1) AS rest, validation_cmd, validation_result, notes
  FROM raw WHERE rest <> ''
  UNION ALL
  SELECT id, ts, agent, task_id, status, trim(substr(rest, 1, instr(rest, ',') - 1)), substr(rest, instr(rest, ',') + 1), validation_cmd, validation_result, notes
  FROM split WHERE rest <> ''
), paths AS (
  SELECT *, lower(path) AS lpath, lower(coalesce(validation_cmd, '')) AS lcmd FROM split WHERE path <> ''
), row_flags AS (
  SELECT
    id, substr(ts, 1, 10) AS day, agent,
    sum(CASE WHEN lpath LIKE 'tests/%' OR lpath LIKE '%/tests/%' OR lpath LIKE 'test_%' OR lpath LIKE '%test_%.py' THEN 1 ELSE 0 END) AS test_path_count,
    sum(CASE WHEN (lpath LIKE 'tests/%' OR lpath LIKE '%/tests/%' OR lpath LIKE 'test_%' OR lpath LIKE '%test_%.py') AND instr(lcmd, lpath) = 0 THEN 1 ELSE 0 END) AS test_paths_not_in_cmd,
    sum(CASE WHEN lpath LIKE 'src/%.hc' OR lpath LIKE 'kernel/%.hc' OR lpath LIKE 'adam/%.hc' OR lpath LIKE 'apps/%.hc' OR lpath LIKE 'compiler/%.hc' THEN 1 ELSE 0 END) AS core_hc_path_count
  FROM paths GROUP BY id
)
SELECT
  'daily_coupling_rates' AS section,
  day, agent, count(*) AS rows,
  sum(test_path_count > 0) AS rows_with_tests,
  sum(test_path_count > 0 AND test_paths_not_in_cmd > 0) AS rows_with_test_target_elision,
  sum(core_hc_path_count > 0) AS rows_with_core_hc,
  sum(core_hc_path_count > 0 AND test_path_count = 0) AS core_rows_without_test_paths
FROM row_flags
GROUP BY day, agent
HAVING rows_with_test_target_elision > 0 OR core_rows_without_test_paths > 0
ORDER BY day DESC, agent;
