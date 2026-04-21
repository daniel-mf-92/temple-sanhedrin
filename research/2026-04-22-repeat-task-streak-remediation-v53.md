# Repeat-task streak remediation v53

Trigger: inference current streak `IQ-989` repeated 4 consecutive iterations.

## Findings (online)
- Use bounded retries with exponential backoff + jitter to prevent retry synchronization and hot-loop amplification.
- Add a circuit-breaker rule for task orchestration: after 3 same-task passes/fails without net delta, force OPEN state and rotate to a different task family.
- Alert on sustained symptoms (streak length / no-progress window) instead of single failures; single failures are noise.

## Concrete loop policy update
- Streak detector key: `(agent, task_id)` consecutive count.
- OPEN threshold: `>=3` consecutive runs with same `task_id` and no new file class touched.
- OPEN action: mark task `blocked-for-rotation`, enqueue two fresh tasks from different subsystem buckets, require one green run outside streak before retrying blocked task.
- Retry budget for same task: max 2 immediate retries, then enforced cool-down 30 min.

## References
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://martinfowler.com/bliki/CircuitBreaker.html
- https://sre.google/workbook/alerting-on-slos/
