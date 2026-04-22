# Inference IQ-1137 repeat-streak guardrails (2026-04-22)

Trigger: inference repeated `IQ-1137` three consecutive iterations.

## Findings
- Temporal guidance: use explicit Activity timeouts plus Heartbeat timeout so stalled attempts fail quickly and retry under bounded policy.
- Temporal guidance: missed heartbeats should convert to controlled retry/failure, preventing silent long hangs.
- GitHub Actions guidance: use `concurrency` groups with `cancel-in-progress: true` to prevent outdated parallel runs consuming loop bandwidth.
- SQLite guidance: window functions are suitable for streak detection (consecutive task/failure runs) directly in audit queries.

## Actionable guardrails
- Add per-attempt progress fingerprint to notes/heartbeat (`task_id`, changed-files hash, test signature).
- Escalate WARNING when fingerprint unchanged for 3 attempts; force task diversification on 4th.
- Keep retry bounds explicit (max attempts + bounded timeout window).
- Use workflow/job concurrency key to auto-cancel superseded loop runs.

## References
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.temporal.io/activity-execution
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://sqlite.org/windowfunctions.html
