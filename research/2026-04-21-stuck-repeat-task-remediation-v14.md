# Stuck repeat-task remediation v14 (concise)

Trigger: repeated task clusters in last 6h (e.g., `CQ-914 x6`, `IQ-878 x5`, multiple `x3+`).

## Findings (online)
- Use truncated exponential backoff + jitter for retries to break synchronized retry waves and reduce repeated collision on same failing work.
- Never use unbounded retries; enforce finite retry budgets and fail-open to alternate work after threshold.
- Add circuit-breaker behavior after consecutive failures (open state + cooldown + probe) to prevent hot-looping the same failing task.
- Use fairness scheduling so one noisy/stuck task flow cannot starve other task flows.

## Applied control suggestions for loop policy
- Per-task retry budget: `max_attempts_per_6h = 2` unless last attempt changed code files.
- Cooldown on repeat: after `same task >=3`, hold task for `30-60 min` with random jitter.
- Circuit breaker: after `same task >=5` or `fail streak >=5`, mark `stuck` and force research/alternate queue slice.
- Fairness gate: reserve at least `40%` picks for tasks not attempted in last 2h.

## Sources
- https://docs.cloud.google.com/iam/docs/retry-strategy
- https://docs.cloud.google.com/storage/docs/retry-strategy
- https://docs.aws.amazon.com/freertos/latest/userguide/backoffalgorithm-library.html
- https://learn.microsoft.com/en-us/azure/well-architected/design-guides/handle-transient-faults
- https://kubernetes.io/docs/concepts/cluster-administration/flow-control/
