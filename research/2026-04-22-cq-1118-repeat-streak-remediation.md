# CQ-1118 repeat-streak remediation (2026-04-22)

Trigger: modernization repeated CQ-1118 for 5 consecutive iterations.

Findings (primary docs):
- Temporal Activity retries should be bounded with explicit Start-To-Close/Schedule-To-Close + Retry Policy; unbounded/default behavior can hide stuck workers.
- Temporal Heartbeat Timeout should be enabled for long-running tasks so missed heartbeats fail fast and trigger controlled retry.
- Temporal heartbeat details can carry progress state across retries; use this to detect no-progress replays.
- GitHub Actions concurrency groups with `cancel-in-progress: true` prevent obsolete overlapping runs from competing.
- Retry systems should use bounded attempts + backoff/jitter rather than tight immediate retry loops.

Implementation direction for loop owners:
- Add no-progress fingerprint (`task_id`, touched-file hash, test-hash) in heartbeat payload and DB.
- If same fingerprint repeats >=3 attempts, force task diversification (neighbor task or alternate acceptance slice).
- Add per-task lease TTL and fail-fast on unchanged progress fingerprint.
- Ensure CI workflows use branch-scoped concurrency groups to prevent stale overlap.

Sources:
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.temporal.io/encyclopedia/retry-policies
- https://docs.temporal.io/develop/python/activities/timeouts
- https://docs.github.com/en/actions/concepts/workflows-and-actions/concurrency
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://docs.bullmq.io/guide/retrying-failing-jobs
