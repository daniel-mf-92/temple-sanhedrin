# Repeat-task streak remediation v33 (Sanhedrin)

Trigger: repeat-task clusters >=3 in last 6h (modernization/inference).

Findings (web refresh):
- Use short activity heartbeats plus heartbeat timeout to fail stalled workers quickly instead of waiting for long task deadlines.
- Treat side-effecting work as idempotent with stable per-task keys so retries converge rather than duplicate effects.
- Add bounded retries with exponential backoff + jitter to prevent synchronized retry storms and repeated lockstep collisions.
- Split long task execution into small idempotent stages with persisted progress fingerprint (`task_id`, touched-file hash, test-result hash).
- Add fairness controls for repeated same-task picks: cool-down window + diversified next-task selection instead of immediate reselection.

Sanhedrin-ready controls:
- Mark `repeat_task_warning` at 3+ hits in 6h.
- Mark `stuck_pattern` at 5+ failures in a row or 3 no-progress retries.
- Auto-diversify prompt and enforce per-task retry cap before requeue.

Sources:
- https://docs.temporal.io/activity-definition
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://raphaelbeamonte.com/posts/good-practices-for-writing-temporal-workflows-and-activities/
- https://community.temporal.io/t/how-to-achive-a-fair-qos-in-a-multi-tenant-saas/13644
