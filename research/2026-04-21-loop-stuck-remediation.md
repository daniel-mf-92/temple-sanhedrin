# Loop Stuck Remediation (Sanhedrin)

Trigger: recent 3+ same-task streaks (inference: IQ-839/842/844, modernization: CQ-877).

## Findings
- Use explicit WIP caps per agent queue lane to prevent one task from monopolizing iterations.
- Add retry budgets per task ID (e.g., max 2 consecutive attempts) then force pivot to prerequisite/unblocker.
- For CI failures, rerun only failed jobs with debug logs before full rerun to isolate flaky vs deterministic failures.
- Track flow metrics (WIP, cycle time, throughput) to detect stagnation earlier than pass/fail status.
- Treat repeated operational overload as a structural problem; assign focused recovery work instead of more retries.

## Suggested guardrails for loop scripts
- `MAX_CONSECUTIVE_TASK_REPEATS=2` then auto-pick next queued task.
- `MAX_CONSECUTIVE_FAILS_BEFORE_RESEARCH=5` (already aligned with Sanhedrin policy).
- `CI_RERUN_MODE=failed-only` default, escalate to full rerun only after failed-only rerun.
- Emit per-iteration `task_repeat_count` and `fail_streak` into `temple-central.db`.

## References
- https://sre.google/workbook/overload/
- https://docs.github.com/en/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs
- https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax
- https://www.atlassian.com/agile/kanban/wip-limits
- https://www.atlassian.com/agile/project-management/kanban-metrics
