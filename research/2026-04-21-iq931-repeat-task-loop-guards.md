# IQ-931 repeat-task loop guards

Date: 2026-04-21
Trigger: inference task `IQ-931` repeated 3 consecutive passes.

Findings (online):
- Add retry budget + bounded attempts; avoid unbounded replays.
- Add circuit-breaker state after repeated same-task executions with low novelty.
- Add exponential backoff + jitter before retrying same task selection.
- Enforce idempotent task execution ledger (`task_id` + artifact hash) to suppress duplicate no-op loops.
- Honor explicit cooldown window before task can be reselected without new failing signal.

References:
- https://learn.microsoft.com/en-us/azure/architecture/antipatterns/retry-storm/
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://microservices.io/patterns/communication-style/idempotent-consumer.html
