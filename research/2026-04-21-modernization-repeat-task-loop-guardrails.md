# Modernization repeat-task loop guardrails (2026-04-21)

Trigger: modernization repeated `CQ-965` for 3 consecutive iterations.

Findings (actionable):
- Add per-task repeat cap: if same `task_id` repeats >=3, force task reselection from next eligible CQ.
- Add cooldown window: completed task cannot be reselected for N iterations unless regression signal appears.
- Apply retry jitter/backoff to avoid synchronized re-runs after transient failures.
- Use CI/workflow concurrency cancellation so stale runs do not keep producing duplicate outcomes.
- Add burn-rate style alerting for loop health: alert on repeated-task ratio and consecutive no-novelty outputs.

Suggested thresholds:
- `same_task_streak >= 3` => research+mitigation required.
- `same_task_streak >= 5` or `fail_streak >= 5` => stuck/critical intervention.
- `novel_files_changed == 0` across 3 iterations => force diversification.

References:
- https://docs.github.com/en/actions/concepts/workflows-and-actions/concurrency
- https://docs.github.com/en/enterprise-cloud%40latest/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://sre.google/workbook/alerting-on-slos/
