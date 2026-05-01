-- Historical token / Book-of-Truth evidence drift audit.
-- Run:
--   sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-01-token-bookoftruth-evidence-drift.sql

WITH builder_rows AS (
  SELECT
    id,
    ts,
    date(ts) AS day,
    agent,
    task_id,
    files_changed,
    validation_cmd,
    validation_result,
    notes,
    lower(
      coalesce(task_id, '') || ' ' ||
      coalesce(files_changed, '') || ' ' ||
      coalesce(validation_cmd, '') || ' ' ||
      coalesce(validation_result, '') || ' ' ||
      coalesce(notes, '')
    ) AS body
  FROM iterations
  WHERE agent IN ('inference', 'modernization')
),
flags AS (
  SELECT
    *,
    body LIKE '%token%' AS token_row,
    (
      body LIKE '%book%truth%' OR
      body LIKE '%book-of-truth%' OR
      body LIKE '%bot_%' OR
      body LIKE '%botgpu%'
    ) AS bot_row,
    (
      body LIKE '%log%' OR
      body LIKE '%ledger%' OR
      body LIKE '%audit%'
    ) AS logish_row,
    (
      body LIKE '%generated%' OR
      body LIKE '%forward%' OR
      body LIKE '%logits%' OR
      body LIKE '%sample%'
    ) AS generation_row,
    (
      body LIKE '%tokenizer%' OR
      body LIKE '%bpe%' OR
      body LIKE '%utf-8%' OR
      body LIKE '%utf8%'
    ) AS tokenizer_row,
    (
      body LIKE '%generate%' OR
      body LIKE '%sampling%' OR
      body LIKE '%topk%' OR
      body LIKE '%topp%' OR
      body LIKE '%greedy%'
    ) AS sampler_row
  FROM builder_rows
)
SELECT
  'overall_token_bot_coverage' AS section,
  agent,
  count(*) AS rows,
  sum(token_row) AS token_rows,
  sum(bot_row) AS bot_rows,
  sum(token_row AND bot_row) AS token_bot_rows,
  sum(token_row AND logish_row) AS token_logish_rows,
  sum(generation_row) AS generation_rows,
  sum(generation_row AND bot_row) AS generation_bot_rows,
  sum(tokenizer_row) AS tokenizer_rows,
  sum(sampler_row) AS sampler_rows
FROM flags
GROUP BY agent
ORDER BY agent;

WITH builder_rows AS (
  SELECT
    id,
    ts,
    date(ts) AS day,
    agent,
    task_id,
    files_changed,
    validation_cmd,
    validation_result,
    notes,
    lower(
      coalesce(task_id, '') || ' ' ||
      coalesce(files_changed, '') || ' ' ||
      coalesce(validation_cmd, '') || ' ' ||
      coalesce(validation_result, '') || ' ' ||
      coalesce(notes, '')
    ) AS body
  FROM iterations
  WHERE agent IN ('inference', 'modernization')
),
flags AS (
  SELECT
    *,
    body LIKE '%token%' AS token_row,
    (
      body LIKE '%book%truth%' OR
      body LIKE '%book-of-truth%' OR
      body LIKE '%bot_%' OR
      body LIKE '%botgpu%'
    ) AS bot_row,
    (
      body LIKE '%generated%' OR
      body LIKE '%forward%' OR
      body LIKE '%logits%' OR
      body LIKE '%sample%'
    ) AS generation_row,
    (
      body LIKE '%tokenizer%' OR
      body LIKE '%bpe%' OR
      body LIKE '%utf-8%' OR
      body LIKE '%utf8%'
    ) AS tokenizer_row,
    (
      body LIKE '%generate%' OR
      body LIKE '%sampling%' OR
      body LIKE '%topk%' OR
      body LIKE '%topp%' OR
      body LIKE '%greedy%'
    ) AS sampler_row
  FROM builder_rows
)
SELECT
  'inference_daily_token_bot_coverage' AS section,
  day,
  count(*) AS rows,
  sum(token_row) AS token_rows,
  sum(token_row AND bot_row) AS token_bot_rows,
  sum(tokenizer_row) AS tokenizer_rows,
  sum(sampler_row) AS sampler_rows,
  sum(generation_row) AS generation_rows
FROM flags
WHERE agent = 'inference'
GROUP BY day
ORDER BY day;

WITH builder_rows AS (
  SELECT
    id,
    ts,
    agent,
    task_id,
    files_changed,
    validation_cmd,
    validation_result,
    notes,
    lower(
      coalesce(task_id, '') || ' ' ||
      coalesce(files_changed, '') || ' ' ||
      coalesce(validation_cmd, '') || ' ' ||
      coalesce(validation_result, '') || ' ' ||
      coalesce(notes, '')
    ) AS body
  FROM iterations
  WHERE agent IN ('inference', 'modernization')
),
flags AS (
  SELECT
    *,
    (
      body LIKE '%book%truth%' OR
      body LIKE '%book-of-truth%' OR
      body LIKE '%bot_%' OR
      body LIKE '%botgpu%'
    ) AS bot_row
  FROM builder_rows
)
SELECT
  'inference_book_of_truth_rows' AS section,
  id,
  ts,
  task_id,
  files_changed,
  validation_result,
  notes
FROM flags
WHERE agent = 'inference'
  AND bot_row = 1
ORDER BY ts;

WITH builder_rows AS (
  SELECT
    id,
    ts,
    agent,
    task_id,
    files_changed,
    validation_cmd,
    validation_result,
    notes,
    lower(
      coalesce(task_id, '') || ' ' ||
      coalesce(files_changed, '') || ' ' ||
      coalesce(validation_cmd, '') || ' ' ||
      coalesce(validation_result, '') || ' ' ||
      coalesce(notes, '')
    ) AS body
  FROM iterations
  WHERE agent IN ('inference', 'modernization')
),
flags AS (
  SELECT
    *,
    body LIKE '%token%' AS token_row,
    (
      body LIKE '%book%truth%' OR
      body LIKE '%book-of-truth%' OR
      body LIKE '%bot_%' OR
      body LIKE '%botgpu%'
    ) AS bot_row
  FROM builder_rows
)
SELECT
  'inference_token_without_bot_samples' AS section,
  id,
  ts,
  task_id,
  files_changed,
  validation_result,
  notes
FROM flags
WHERE agent = 'inference'
  AND token_row = 1
  AND bot_row = 0
ORDER BY ts
LIMIT 20;
