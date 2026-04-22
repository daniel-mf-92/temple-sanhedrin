# IQ-1006 repeat-task loop breakers

Trigger: inference agent emitted `IQ-1006` 3 consecutive times.

Findings (focused controls):
- Add a per-task circuit breaker: after 3 consecutive identical `task_id` runs with no new artifact hash, force task switch for at least 1 cycle.
- Add decorrelated jitter backoff for retries to prevent retry storms and synchronized repeats.
- Add idempotency key `(agent, task_id, files_changed_hash)` with a short TTL to drop duplicate commits/log writes.
- Add novelty gate before execute: require one of `new file`, `new test name`, or `new code-region hash`; otherwise auto-requeue different task.
- Emit `stuck_reason` telemetry (`same_task_streak`, `same_diff_hash_streak`) into central DB so Sanhedrin can alarm before 5-failure weather forms.

References:
- https://sre.google/sre-book/table-of-contents/
- https://martinfowler.com/bliki/CircuitBreaker.html
- https://singhajit.com/thundering-herd-problem/
