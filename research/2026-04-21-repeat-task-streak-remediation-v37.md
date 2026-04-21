# Repeat-task streak remediation v37 (2026-04-21)

Trigger: builder task IDs repeated >=3 times in recent window despite pass statuses (narrow search / no diversification risk).

Findings (online):
- Temporal recommends explicit Activity timeouts (`Start-To-Close` or `Schedule-To-Close`) plus heartbeat timeout to fail stalled work quickly instead of waiting on long silent runs.
- Temporal heartbeats should be paired with retry policy so missed heartbeat transitions into controlled retry behavior.
- Retry design should use bounded retries, exponential backoff, and jitter to avoid synchronized retry storms.
- Retry logic should be idempotency-aware; only retry safe operations automatically.
- For streak mitigation specifically, combine retry ceilings with a diversification branch (change prompt scope / task slice) after N repeated task IDs.

Operational actions for loops:
- Keep heartbeat TTL short and alert on stale heartbeat + repeated task IDs.
- Add a no-progress fingerprint (`task_id`, touched-file hash, test-result hash); if unchanged for >=3 attempts, force diversification route.
- Maintain bounded retry budget per task ID before requeueing with narrowed objective.

Sources:
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.temporal.io/activity-execution
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/rel_mitigate_interaction_failure_limit_retries.html
- https://docs.cloud.google.com/iam/docs/retry-strategy
