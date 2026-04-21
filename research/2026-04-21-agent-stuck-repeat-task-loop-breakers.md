# Repeat-task loop breakers (stuck-pattern mitigation)

Trigger: repeated task streaks observed (>=3), including IQ-989 x4 and multiple historical clusters.

Findings:
- Use bounded retries with exponential backoff + jitter to prevent synchronized retry storms and cascading failures.
- Classify retryable vs non-retryable failures; skip retries for deterministic/code errors.
- Enforce max-attempt caps and route exhausted attempts to quarantine/DLQ for human/agent diagnosis.
- Require idempotent task effects and duplicate suppression keys so repeated executions do not reapply same state change.
- Add observability on retry count, same-task streak length, and “no-diff pass” rate; auto-escalate when streak >=5.

Applied recommendations for Temple loops:
- Keep current “single failure = INFO”, but auto-switch to alternate task class when same task repeats 3 times.
- At streak 5, force research mode + architecture pivot notes before next assignment.
- Add cooldown window for same task_id requeue unless new file diff fingerprint is detected.

Sources:
- https://docs.temporal.io/encyclopedia/retry-policies
- https://sre.google/sre-book/addressing-cascading-failures/
- https://docs.cloud.google.com/storage/docs/retry-strategy
