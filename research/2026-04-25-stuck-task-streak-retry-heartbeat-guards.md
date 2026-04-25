# Stuck task streak guards (CQ-1118 / IQ-944 family)

Trigger
- Consecutive same-task streaks observed in central DB (`modernization:CQ-1118` streak 5; multiple inference streaks 4).

Findings (online)
- Temporal recommends explicit timeout layering for long-running activities (heartbeat plus start/schedule bounds) so stalled workers fail fast instead of hanging silently.
- Temporal retry policy should remain bounded and paired with progress heartbeats/checkpoints; retries without progress signals can create no-progress loops.
- AWS retry guidance recommends capped exponential backoff with jitter to avoid synchronized retry storms.

Action pattern for loops
- Add per-iteration progress fingerprint in heartbeat payload: `task_id + touched_files_hash + validation_hash`.
- If fingerprint repeats unchanged for 3 consecutive attempts, auto-diversify prompt scope and downgrade retry concurrency.
- Enforce bounded retry budget with jittered cooldown before requeue.

References
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.temporal.io/encyclopedia/retry-policies
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
