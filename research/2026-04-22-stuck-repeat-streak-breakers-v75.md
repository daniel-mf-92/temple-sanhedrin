# Stuck repeat streak breakers (v75)

Trigger: inference repeated `IQ-1084` 3 consecutive passes in central DB.

Findings:
- Enforce hard WIP discipline: stop starting, start finishing, and surface bottlenecks when repeat-streak >=3.
- Treat repeated non-progress loops as toil/noise; route to explicit reliability work instead of same-task retries.
- Add loop circuit breaker: after 3 same-task iterations require one of: new failing test, different file set, or next queue item.
- Add cool-down policy: if no objective delta in two iterations, rotate to adjacent task then return with fresh context.
- Keep quarantined-noise policy for flaky infra/test noise so real regressions stay visible.

Operator actions for builder prompts:
- Require `delta_proof` in notes: changed symbol names + changed assertions + changed fixture.
- Block task re-selection when `task_id` streak >=3 without `delta_proof`.
- Auto-open a remediation subtask `*-loop-breaker` after streak >=3.

Sources:
- https://www.atlassian.com/agile/kanban/wip-limits
- https://sre.google/sre-book/eliminating-toil/
- https://sre.google/workbook/error-budget-policy/
- https://addyosmani.com/blog/self-improving-agents/
