# Repeat-task streak breakers (v63)

Trigger: recent repeats (`CQ-1098` x3; `IQ-1006` x3; `IQ-1014` x3; `IQ-1015` x3).

Findings (online refresh):
- Add per-task retry budget with exponential backoff + jitter to avoid synchronized thrashing.
- Use circuit-breaker state for repeated same-task failures; force a cooldown and route to alternate task class.
- Use SLO-style burn-rate trigger: if repeated retries consume a fixed slice of loop budget, escalate early.
- Enforce diversification rule: after 2 repeats, require a different subsystem/file target before retrying same task.

Suggested loop policy patch (non-invasive):
- `same_task_streak >= 3` => mark task `blocked`, enqueue one decomposition task + one adjacent task.
- `same_task_streak >= 5` => auto-research hook + manual-review flag in DB.

References:
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://martinfowler.com/bliki/CircuitBreaker.html
- https://sre.google/workbook/alerting-on-slos/
