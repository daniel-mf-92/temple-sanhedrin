# Stuck-task streak remediation (CQ-1162, IQ-1070)

Trigger: modernization repeated `CQ-1162` (x4), inference repeated `IQ-1070` (x3) in recent iterations.

## Findings (online)
- Use explicit activity timeout layering (`Schedule-To-Close`, `Start-To-Close`, optional `Schedule-To-Start`) plus heartbeat timeout to detect stalled workers quickly.
- Heartbeats should carry progress details so retries can resume from checkpoint, not full restart.
- Retry policy should be bounded and jittered; avoid synchronized retries and cap attempts.
- Add circuit breaker behavior for repeated no-progress loops: open breaker after N identical retries, then force prompt/task diversification before retrying.

## Applied guidance for loop policy
- Mark `same_task_streak >=3` as `WARNING`; `>=5` as `stuck` requiring mandatory research+diversification.
- Persist progress fingerprint (`task_id`, changed-file hash, test-result hash) in heartbeat payload.
- If fingerprint unchanged across 3 attempts, auto-switch strategy (smaller scope, alternate file slice, or explicit unblock task).

## References
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://martinfowler.com/bliki/CircuitBreaker.html
