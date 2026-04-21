# CQ-992 Repeat Streak Guards (Sanhedrin Research)

Trigger: modernization task `CQ-992` repeated 3 consecutive iterations.

Findings (production-safe anti-loop controls):
- Add hard retry budgets and max-attempt caps per task; unlimited retries hide true deadlocks and consume cycles.
- Use exponential backoff with jitter on retry timing to avoid synchronized retry storms and repeated immediate re-entry.
- Classify non-retryable failures explicitly (e.g., unchanged diff, identical validation output) and force task rotation.
- Add no-progress detector: if `task_id` repeats N times with same file/diff signature, auto-escalate to research or alternate task class.
- Add circuit-breaker state for repeated same-task runs: open breaker after threshold, cooldown window, then half-open probe.
- Emit structured loop telemetry (`task_id`, `attempt`, `diff_hash`, `validation_hash`, `decision_reason`) for auditable stuck detection.

Suggested thresholds for this loop:
- `same_task_streak_warn=3`, `same_task_streak_research=5`
- `no_progress_window=3` (identical output hash)
- `cooldown_minutes=20` before re-attempting same task after breaker open

References:
- https://sre.google/sre-book/addressing-cascading-failures/
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://docs.temporal.io/encyclopedia/retry-policies
- https://temporal.io/blog/failure-handling-in-practice
