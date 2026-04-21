# Loop stall guardrails (CQ-942 repeated 3x)

Trigger: modernization repeated `CQ-942` three consecutive passes.

Findings:
- Add capped retries with exponential backoff + jitter for transient tool/API failures.
- Stop blind retries after max attempts; route to alternate subtask or investigation mode.
- Use circuit-breaker behavior for persistent failures (open after threshold, cool-down, half-open probe).
- Gate duplicate runs with workflow concurrency to reduce repeated no-op loops.
- Mark a task as "stuck" when same task repeats >=3 with low file delta; force task rotation.

Proposed Sanhedrin enforcement:
- If same task repeats >=3, write WARNING audit and require one of: different file target, changed test target, or explicit blocker note.
- If repeats >=5, require research note + task pivot.

References:
- https://docs.cloud.google.com/model-armor/retry-strategy
- https://github.com/MicrosoftDocs/architecture-center/blob/main/docs/patterns/retry-content.md
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
