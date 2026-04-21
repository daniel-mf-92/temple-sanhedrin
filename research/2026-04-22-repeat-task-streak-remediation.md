# Repeat-task streak remediation (sanhedrin)

Trigger: repeated same-task runs (>=3) observed in `iterations` (latest includes inference IQ-980 x3).

Findings (external):
- Use bounded retries with exponential backoff + jitter to avoid synchronized retry storms and repeated no-op attempts.
- Add a circuit-breaker threshold so once a task repeats N times without net delta, force a state transition instead of retrying same plan.
- Separate transient/tool errors from deterministic logic failures; retry only transient classes.

Controls to apply in loop policy:
1) `same_task_streak >= 3` => require strategy mutation (new test vector, different file-slice, or decomposition).
2) `same_task_streak >= 5` => hard stop on task; enqueue blocker-analysis task and switch queue item.
3) Record `streak_reason` taxonomy (`tool`, `test`, `design`, `scope`) to prevent repeated generic retries.

References:
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://sre.google/sre-book/addressing-cascading-failures/
- https://martinfowler.com/bliki/CircuitBreaker.html
