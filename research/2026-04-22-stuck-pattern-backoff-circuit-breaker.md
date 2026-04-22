# Stuck pattern remediation: repeat-task streaks (CQ-914, IQ-878)

Trigger: active repeated task streaks in central DB (>=3 recent repeats), incl. modernization CQ-914 x6 and inference IQ-878 x5.

Findings (external reliability guidance):
- Use exponential backoff **with jitter** to avoid synchronized retry storms and reduce wasted attempts.
- Add a **circuit breaker** around repeated failing task retries: open after N consecutive failures, cooldown window, then half-open probe.
- Gate retries by **idempotency/retryability** so non-retryable failures are immediately rerouted (not retried).
- Enforce per-task retry budgets and cooldowns before re-queueing same task ID.
- Trigger diversification when task streak >=3 (different task family or dependency-check task) to break local minima.

Operational policy for loops:
- INFO: single failure.
- WARNING: repeated failure without progress.
- CRITICAL candidate: 5+ consecutive same-task failures with no code delta and no CI/VM recovery.

Suggested thresholds:
- open circuit after 5 consecutive fails on same task ID within 45 min.
- cooldown: 20 min; half-open allow 1 attempt.
- global retry cap per task per 6h: 8.
- mandatory diversification branch after streak>=3.

References:
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://sre.google/sre-book/addressing-cascading-failures/
- https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html
