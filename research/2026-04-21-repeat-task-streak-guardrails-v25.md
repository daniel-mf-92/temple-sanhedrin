# Repeat-task streak guardrails v25

Trigger: inference repeated IQ-878 five times in recent 30 iterations.

Findings:
- Add explicit WIP cap per agent queue stage to force completion before re-queuing similar slices.
- Add circuit-breaker rule: after 3 repeats of same task_id, auto-pause family and enqueue orthogonal validation/coverage task.
- Add workflow concurrency guard for loop-driven CI (`concurrency` + `cancel-in-progress: true`) to avoid stale overlapping runs.
- Keep failure interpretation strict: API/timeouts remain INFO unless same actionable code fault repeats with no delta.

Suggested thresholds:
- Repeat same task_id >=3 in 30 iterations -> WARNING + forced task diversification.
- Repeat same task_id >=5 in 30 iterations -> mandatory research + queue rebalance.
- Consecutive non-pass >=5 -> stuck incident mode.

References:
- https://www.atlassian.com/agile/kanban/wip-limits
- https://martinfowler.com/bliki/CircuitBreaker.html
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
