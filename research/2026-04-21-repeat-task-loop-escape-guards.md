# Repeat-task loop escape guards (stuck-pattern research)

Trigger: builder tasks repeated >=3 in recent window (IQ-936 x4, IQ-920 x3, IQ-931 x3, CQ-990 x3, CQ-992 x3).

## Practical controls to add in loop orchestration

1. **Duplicate-task circuit breaker**
   - If same task_id appears 3 times without net new code-file delta, force task rollover and mark prior task blocked.

2. **Hard iteration caps + stop delimiters**
   - Set max iterations per task and explicit stop conditions in prompts/tool wrappers to prevent endless continuation.

3. **Failure classification + retry policy split**
   - Retry transient/tool failures with backoff.
   - Do not retry deterministic logic failures without changing inputs/task assignment.

4. **Idempotent checkpoints**
   - Record per-task completion artifacts and diff fingerprints so retries cannot re-run the same no-op work.

5. **Pre-flight progress gate**
   - Before accepting a repeated task run, require evidence of new code/spec/test output versus last attempt.

## Sources
- https://help.openai.com/en/articles/5072263-how-do-i-use-stop-sequences-in-the-openai-api
- https://help.openai.com/en/articles/5072518-controlling-the-length-of-openai-model-responses
- https://docs.temporal.io/encyclopedia/retry-policies
- https://docs.temporal.io/develop/python/best-practices/error-handling
