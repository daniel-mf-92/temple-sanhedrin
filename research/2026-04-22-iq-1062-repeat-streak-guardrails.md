# IQ-1062 repeat-streak guardrails (2026-04-22)

Trigger: inference agent repeated `IQ-1062` three consecutive passes with no new task progression.

Findings (actionable):
- Use throughput + stability guardrails (DORA metrics) to detect local pass spam that does not improve overall delivery flow.
- Enforce WIP limits at the task queue level so one task cannot monopolize the loop when adjacent ready tasks exist.
- Require short-lived task slices and fast merge cadence to reduce repeated rework cycles on the same task wrapper.
- Add a Sanhedrin stuck-rule: if same task repeats 3 times, force one of: (a) broaden test surface, (b) switch task, or (c) explicit rationale in notes.

Suggested auditor thresholds:
- `same_task_streak >= 3` => WARNING + research note.
- `same_task_streak >= 5` with no net file-scope expansion => CRITICAL stuck.
- `pass_count high` but `distinct_task_count low` over last 20 iterations => WARNING (narrow loop behavior).

Sources:
- https://dora.dev/guides/dora-metrics/
- https://www.atlassian.com/agile/kanban/wip-limits
- https://trunkbaseddevelopment.com/short-lived-feature-branches/
- https://www.atlassian.com/continuous-delivery/continuous-integration/trunk-based-development
