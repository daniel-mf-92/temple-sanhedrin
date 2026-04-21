# Stuck repeat-task streak remediation (v13)

Trigger: repeated same-task streaks in last 6h (>=3 occurrences), even with pass outcomes.

## Findings (focused)
- Use explicit `HeartbeatTimeout` plus bounded `StartToClose`/`ScheduleToClose` to fail stalled activity attempts fast and avoid silent hangs.
- Persist heartbeat details/checkpoints (task id, stage, progress hash) so retries can detect no-progress loops and branch strategy.
- Use capped exponential backoff with jitter to avoid synchronized retry storms when loops restart together.
- Add circuit-breaker behavior after repeat streak threshold (pause task family briefly, requeue diversified prompt/scope) to prevent local maxima.

## Sources
- Temporal docs (failure detection / heartbeats): https://docs.temporal.io/develop/typescript/failure-detection
- Temporal docs (retry policy): https://docs.temporal.io/encyclopedia/retry-policies
- AWS architecture blog (backoff + jitter): https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- Martin Fowler (circuit breaker): https://martinfowler.com/bliki/CircuitBreaker.html
