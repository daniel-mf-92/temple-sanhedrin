# Research: inference repeat-task streak (IQ-1024)

Trigger: inference task `IQ-1024` repeated 3 consecutive iterations.

Findings (online):
- Temporal recommends explicit Activity timeouts (`Start-To-Close` or `Schedule-To-Close`) plus heartbeat timeout so stalled work fails fast instead of silently repeating.
- Temporal heartbeat details can persist progress state across retries; use this to detect no-progress retries and branch to a narrower fallback prompt.
- GitHub Actions `concurrency` with `cancel-in-progress: true` prevents stacked stale runs and keeps only the latest attempt active.

Applied Sanhedrin guidance:
- Mark 3x same-task streak as WARNING and require strategy shift before 5x.
- Attach progress fingerprint (`task_id`, touched-file hash, test hash) to each loop heartbeat/iteration note.
- If fingerprint unchanged for 3 attempts, force alternate execution mode (smaller scope + different validation path).

Sources:
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.temporal.io/develop/python/activities/timeouts
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
