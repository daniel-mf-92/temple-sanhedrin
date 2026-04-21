# Stuck-pattern retry guardrails (v38)

Trigger: modernization task repeated 3+ times in recent window.

## Findings (online)
- Temporal recommends combining explicit activity timeouts (Start-To-Close / Schedule-To-Close) with heartbeat timeout so stalled workers fail fast instead of hanging indefinitely.
- Temporal retry policy is declarative and should be tuned; retries are useful for transient errors but must be bounded.
- Temporal activity guidance emphasizes idempotent activities because retries are expected.
- AWS guidance recommends exponential backoff with jitter and capped retries to reduce retry storms and contention.

## Suggested controls for builder loops
- Keep heartbeat timeout short enough to detect stalls quickly.
- Bound retry attempts per task, then force diversification/escalation path.
- Persist progress fingerprint (task_id + touched-files hash + test hash) and detect no-progress repeats.
- Use exponential backoff + jitter for retried loop attempts.

## References
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.temporal.io/encyclopedia/retry-policies
- https://docs.temporal.io/activities
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html
