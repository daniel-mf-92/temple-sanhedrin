# IQ-1092 streak guardrails (2026-04-22)

Trigger: inference agent repeated `IQ-1092` for 3 consecutive iterations.

## Findings
- Add a hard per-task streak cap (`max_same_task_streak=2`) and force task rotation once exceeded.
- Keep retries only for transient faults, and use truncated exponential backoff + jitter to avoid retry storms.
- Add a circuit breaker for repeated same-task attempts: open after threshold, cool down, then half-open probe.
- Require explicit "novelty evidence" before allowing the same task ID again (new failing test, new diff target, or new acceptance gap).
- Add retry budget per task window (for example: max 2 retries per 30 minutes), then auto-escalate to queue reselection.

## Proposed loop policy deltas
- `same_task_streak >= 3` => mark task as temporarily frozen for one cycle.
- If task reappears after freeze with no new evidence, reject and pick next queue item.
- Log freeze/unfreeze events to central DB for observability.

## References
- AWS Prescriptive Guidance: Retry with backoff
- AWS Well-Architected REL05-BP03 (limit retries + jitter)
- Google Cloud retry strategy (idempotency + truncated exponential backoff with jitter)
- Martin Fowler circuit breaker pattern

