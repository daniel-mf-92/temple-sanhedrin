# Repeat-task loop remediation (Sanhedrin)

Trigger: repeated task IDs (>=3) across builder agents despite pass status.

Findings (online, concise):
- Add capped exponential backoff with jitter for requeue/retry decisions to avoid synchronized retry storms.
- Enforce one retry authority (single layer) to prevent multiplicative retry amplification.
- Add circuit-breaker cooldown after bounded no-progress attempts to force task-class rotation.
- Gate retries with idempotency key + progress hash; if hash unchanged N times, block immediate re-run.
- Escalate to research/architecture intervention when same task id repeats >=3 and no file-class progress.

Actionable policy for loops:
1) max_attempts_per_task=3 before cooldown
2) cooldown_min=15 with jitter
3) no_progress_hash_window=3 => force alternate task domain
4) retry_only_on_transient failures, never on deterministic lint/schema failures without diff
5) keep failure streak threshold at 5 for hard "stuck" state

References:
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://sre.google/sre-book/addressing-cascading-failures/
- https://learn.microsoft.com/en-us/azure/architecture/patterns/retry
- https://martinfowler.com/bliki/CircuitBreaker.html
