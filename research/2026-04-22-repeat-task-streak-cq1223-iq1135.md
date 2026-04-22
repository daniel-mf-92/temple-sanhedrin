# Repeat-task streak guardrails (CQ-1223 / IQ-1135)

- Trigger: modernization `CQ-1223` repeated 4x in recent window; inference `IQ-1135` repeated 3x.
- Temporal docs recommend explicit `Heartbeat Timeout` + bounded `Start-To-Close`/`Schedule-To-Close` and retry policies so stalled workers fail fast and retry deterministically.
- Temporal docs note heartbeat details can carry progress state; use payload fingerprints (`task_id`, changed files hash, test signature) to detect no-progress repeats.
- GitHub Actions docs support focused reruns with debug logging and workflow troubleshooting; use this only after task diversification to avoid blind rerun loops.
- SRE guidance: alert on significant events (repeat/no-progress threshold), not on single transient failures.

References:
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.temporal.io/encyclopedia/retry-policies
- https://docs.github.com/en/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs
- https://docs.github.com/en/actions/how-tos/troubleshoot-workflows
- https://sre.google/workbook/alerting-on-slos/
