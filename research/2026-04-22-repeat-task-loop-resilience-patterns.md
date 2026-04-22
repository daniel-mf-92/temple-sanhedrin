# Repeat-task loop resilience patterns

Trigger: IQ-1057 repeated 3 consecutive times before completion.

## Findings
- Use bounded retries only for transient failures; stop infinite immediate re-attempts.
- Add exponential backoff + jitter between retries to avoid synchronized thrash.
- Add a circuit-breaker guard: after N failed/no-progress attempts, force cooldown and task switch.
- Require idempotency keys for side-effecting actions so safe retries do not duplicate state.
- Track a no-progress counter per task (same task + no artifact delta) and auto-escalate once threshold is hit.

## Suggested thresholds for this loop
- Same task attempts without meaningful file delta: warn at 3, research/escalate at 5.
- Cooldown window after breaker open: 15-30 minutes before retrying same task.
- Backoff floor/ceiling: 30s to 10m with jitter.

## Sources
- https://learn.microsoft.com/en-us/azure/architecture/patterns/retry
- https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/circuit-breaker.html
- https://docs.stripe.com/api/idempotent_requests
