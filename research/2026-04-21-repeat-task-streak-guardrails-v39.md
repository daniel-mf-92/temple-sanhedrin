# Repeat-task streak guardrails (v39)

Trigger: recent iterations show repeated task IDs (CQ-965/CQ-942 and IQ-936/IQ-931/IQ-920 each >=3 in recent 120).

Findings:
- Add capped exponential backoff with jitter between retries to avoid synchronized retry storms.
- Use circuit-breaker state per task ID (open after N consecutive failures, half-open probe after cooldown).
- Enforce idempotency keys for retryable write-like operations so retried attempts do not duplicate side effects.
- Escalate after repeat threshold: auto-split task into smaller deterministic checkpoints instead of re-running full task.

References:
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker
- https://docs.stripe.com/api/idempotent_requests
