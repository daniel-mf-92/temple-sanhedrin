# Repeat-task loop remediation v2

Trigger: repeated task IDs (>=3) across recent builder iterations despite pass status.

Findings:
- Use capped exponential backoff with jitter for requeue/retry paths to avoid synchronized retry storms.
- Bound retries per task and enforce cooldown before same-task reattempt.
- Treat retries as single-layer ownership to avoid multiplicative amplification.
- Use idempotency keys plus no-progress hashes; if unchanged across N runs, force task-class rotation.
- Route deterministic failures (lint/schema/static checks) to fix-first queues instead of blind retry.
- Keep hard stuck threshold at 5+ consecutive non-pass outcomes; treat isolated failures as informational.

Suggested guardrails:
1) max_attempts_per_task=3
2) cooldown_minutes=15 (+ jitter)
3) no_progress_hash_window=3
4) retry_only_transient=true
5) escalate_research_on_repeat_task_ids>=3

References:
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://learn.microsoft.com/en-us/azure/architecture/patterns/retry
- https://learn.microsoft.com/en-us/azure/architecture/antipatterns/retry-storm/
- https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker
- https://sre.google/sre-book/addressing-cascading-failures/
- https://martinfowler.com/bliki/CircuitBreaker.html
