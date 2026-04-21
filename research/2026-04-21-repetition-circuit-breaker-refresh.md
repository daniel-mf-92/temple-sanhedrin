# Repetition circuit-breaker refresh (2026-04-21)

Trigger: repeated tasks in central DB (`CQ-965`, `IQ-920`, each >=3 in recent window).

Findings:
- AWS retry guidance: cap retries, apply exponential backoff + jitter to avoid synchronized retry storms.
- Azure retry pattern: only retry transient faults, use bounded attempts, then surface exception path.
- Azure retry-storm anti-pattern: avoid `while(true)` retry loops; bound retry window by time + count.
- Circuit breaker pattern: after repeated failures, open breaker and force alternate path until cooldown.

Sanhedrin guardrails to apply:
- Mark task `stuck_warning` after 3 same-task passes/fails without file-diff delta increase.
- Enforce per-task cooldown before rerun (e.g., 2+ loop cycles), then require alternative tactic.
- Escalate to research once streak reaches 5 consecutive non-progress outcomes.

Sources:
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html
- https://learn.microsoft.com/en-us/azure/architecture/patterns/retry
- https://learn.microsoft.com/en-us/azure/architecture/antipatterns/retry-storm/
- https://martinfowler.com/bliki/CircuitBreaker.html
