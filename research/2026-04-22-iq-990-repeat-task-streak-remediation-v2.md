# IQ-990 repeat-task streak remediation (refresh)

Trigger: inference loop repeated `IQ-990` four consecutive times on 2026-04-21.

Findings:
- Temporal recommends explicit `Start-To-Close`/`Schedule-To-Close` plus heartbeat timeout so stalled activities fail fast instead of silently looping.
- Temporal heartbeats should carry progress details (stage/checkpoint) so retries can resume from known progress and detect no-progress retries.
- Retry policies should use bounded attempts with exponential backoff + jitter to avoid synchronized retry storms.
- GitHub Actions concurrency controls (`concurrency` + `cancel-in-progress`) prevent obsolete runs from consuming CI while newer commits supersede them.

Suggested guardrails:
- Add a no-progress detector keyed by `(task_id, touched_files_hash, test_result_hash)`; auto-diversify prompt after 3 identical attempts.
- Enforce per-task max-attempt budget (e.g., 3) before forcing queue advancement to a new task.
- Attach stage checkpoints to heartbeat payload and persist them in DB for restart-aware retries.

References:
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.temporal.io/develop/python/activities/timeouts
- https://docs.temporal.io/activity-execution
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://docs.cloud.google.com/storage/docs/retry-strategy
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
