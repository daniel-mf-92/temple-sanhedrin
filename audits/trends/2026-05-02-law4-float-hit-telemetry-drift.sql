-- Historical drift trend audit: Law 4 float-hit telemetry shape drift.
-- Source DB: /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db
--
-- Re-run:
--   sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-02-law4-float-hit-telemetry-drift.sql

-- Overall Law 4 float-hit evidence surface in Sanhedrin AUDIT rows.
WITH law4_float AS (
  SELECT id, ts, status, notes, lower(notes) AS n
  FROM iterations
  WHERE agent = 'sanhedrin'
    AND task_id = 'AUDIT'
    AND lower(notes) LIKE '%law4%float%'
),
shape AS (
  SELECT *,
    CASE
      WHEN instr(n, 'law4_float_hits=') > 0 THEN 'underscore_equals'
      ELSE 'other_law4_float'
    END AS evidence_shape
  FROM law4_float
)
SELECT
  count(*) AS total_rows,
  min(ts) AS first_ts,
  max(ts) AS last_ts
FROM shape;

-- Shape split: only underscore_equals is directly machine-parseable by simple key=value logic.
WITH law4_float AS (
  SELECT id, ts, status, notes, lower(notes) AS n
  FROM iterations
  WHERE agent = 'sanhedrin'
    AND task_id = 'AUDIT'
    AND lower(notes) LIKE '%law4%float%'
),
shape AS (
  SELECT *,
    CASE
      WHEN instr(n, 'law4_float_hits=') > 0 THEN 'underscore_equals'
      ELSE 'other_law4_float'
    END AS evidence_shape
  FROM law4_float
)
SELECT
  evidence_shape,
  count(*) AS rows,
  min(ts) AS first_ts,
  max(ts) AS last_ts
FROM shape
GROUP BY evidence_shape
ORDER BY rows DESC;

-- Daily shape migration.
WITH law4_float AS (
  SELECT id, ts, status, notes, lower(notes) AS n
  FROM iterations
  WHERE agent = 'sanhedrin'
    AND task_id = 'AUDIT'
    AND lower(notes) LIKE '%law4%float%'
),
shape AS (
  SELECT *,
    CASE
      WHEN instr(n, 'law4_float_hits=') > 0 THEN 'underscore_equals'
      ELSE 'other_law4_float'
    END AS evidence_shape
  FROM law4_float
)
SELECT
  substr(ts, 1, 10) AS day,
  evidence_shape,
  count(*) AS rows
FROM shape
GROUP BY day, evidence_shape
ORDER BY day, evidence_shape;

-- Head parseability for the key=value rows.
WITH rows AS (
  SELECT
    id,
    ts,
    notes,
    lower(notes) AS n,
    substr(lower(notes), instr(lower(notes), 'law4_float_hits=') + 16) AS rest
  FROM iterations
  WHERE agent = 'sanhedrin'
    AND task_id = 'AUDIT'
    AND instr(lower(notes), 'law4_float_hits=') > 0
),
classified AS (
  SELECT *,
    CASE
      WHEN rest glob '[0-9]*' THEN 'numeric_head'
      ELSE 'text_head'
    END AS head_kind
  FROM rows
)
SELECT
  head_kind,
  count(*) AS rows,
  min(ts) AS first_ts,
  max(ts) AS last_ts
FROM classified
GROUP BY head_kind
ORDER BY rows DESC;

-- Numeric values parsed from the key=value rows. The 1222 row is retained as evidence of
-- delimiter drift rather than treated as a true source-hit count.
WITH rows AS (
  SELECT
    id,
    ts,
    lower(notes) AS n,
    substr(lower(notes), instr(lower(notes), 'law4_float_hits=') + 16) AS rest
  FROM iterations
  WHERE agent = 'sanhedrin'
    AND task_id = 'AUDIT'
    AND instr(lower(notes), 'law4_float_hits=') > 0
),
parsed AS (
  SELECT
    id,
    ts,
    rest,
    CASE
      WHEN rest glob '[0-9]*' THEN cast(substr(rest, 1,
        CASE
          WHEN instr(rest, '(') > 0
            AND (instr(rest, ' ') = 0 OR instr(rest, '(') < instr(rest, ' '))
            AND (instr(rest, ';') = 0 OR instr(rest, '(') < instr(rest, ';'))
            THEN instr(rest, '(') - 1
          WHEN instr(rest, ';') > 0
            AND (instr(rest, ' ') = 0 OR instr(rest, ';') < instr(rest, ' '))
            THEN instr(rest, ';') - 1
          WHEN instr(rest, ' ') > 0 THEN instr(rest, ' ') - 1
          ELSE length(rest)
        END) AS integer)
    END AS hits
  FROM rows
)
SELECT
  hits,
  count(*) AS rows,
  min(ts) AS first_ts,
  max(ts) AS last_ts
FROM parsed
WHERE hits IS NOT NULL
GROUP BY hits
ORDER BY hits;

-- Representative rows whose key=value value is textual, not numeric.
WITH rows AS (
  SELECT
    id,
    ts,
    notes,
    lower(notes) AS n,
    substr(lower(notes), instr(lower(notes), 'law4_float_hits=') + 16) AS rest
  FROM iterations
  WHERE agent = 'sanhedrin'
    AND task_id = 'AUDIT'
    AND instr(lower(notes), 'law4_float_hits=') > 0
),
classified AS (
  SELECT *,
    CASE
      WHEN rest glob '[0-9]*' THEN 'numeric_head'
      ELSE 'text_head'
    END AS head_kind
  FROM rows
)
SELECT
  id,
  ts,
  substr(notes, max(1, instr(lower(notes), 'law4_float_hits=') - 72), 180) AS snippet
FROM classified
WHERE head_kind = 'text_head'
LIMIT 12;

-- The parser-hostile numeric outlier.
WITH rows AS (
  SELECT
    id,
    ts,
    notes,
    lower(notes) AS n,
    substr(lower(notes), instr(lower(notes), 'law4_float_hits=') + 16) AS rest
  FROM iterations
  WHERE agent = 'sanhedrin'
    AND task_id = 'AUDIT'
    AND instr(lower(notes), 'law4_float_hits=') > 0
),
parsed AS (
  SELECT
    id,
    ts,
    notes,
    rest,
    CASE
      WHEN rest glob '[0-9]*' THEN cast(substr(rest, 1,
        CASE
          WHEN instr(rest, '(') > 0
            AND (instr(rest, ' ') = 0 OR instr(rest, '(') < instr(rest, ' '))
            AND (instr(rest, ';') = 0 OR instr(rest, '(') < instr(rest, ';'))
            THEN instr(rest, '(') - 1
          WHEN instr(rest, ';') > 0
            AND (instr(rest, ' ') = 0 OR instr(rest, ';') < instr(rest, ' '))
            THEN instr(rest, ';') - 1
          WHEN instr(rest, ' ') > 0 THEN instr(rest, ' ') - 1
          ELSE length(rest)
        END) AS integer)
    END AS hits
  FROM rows
)
SELECT
  id,
  ts,
  hits,
  substr(notes, max(1, instr(lower(notes), 'law4_float_hits=') - 72), 180) AS snippet
FROM parsed
WHERE hits > 500
ORDER BY hits DESC;
