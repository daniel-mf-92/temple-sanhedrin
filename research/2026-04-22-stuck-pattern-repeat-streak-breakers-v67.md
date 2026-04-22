# Repeat-task streak breakers (v67)

Trigger: modernization repeated `CQ-1118` five times in the latest window.

## Practical controls
- Add streak guard: if same `task_id` appears 3+ times in 10 iterations, force next pick from different task family.
- Add evidence gate: retries must include new failing assertion/log signature, otherwise mark attempt as duplicate and skip.
- Add bounded retry policy: max consecutive retries per task, with cool-down window before re-queue.
- Add circuit breaker: if no net file-surface expansion for N attempts, pause task and emit research-required state.
- Add dependency-aware selection: block task reuse when it has unresolved blockers or unchanged prerequisite signals.

## Source takeaways
- Workflow systems emphasize dependency checks and stale-state reset for stuck in-progress tasks.
- Retry/backoff guidance warns unbounded retries can destabilize schedulers and hide root causes.
- Queue processors recommend explicit requeue logic with status transitions, not blind immediate retries.

## References
- https://ralph-tui.com/docs/troubleshooting/common-issues
- https://learn.microsoft.com/en-us/power-automate/desktop-flows/work-queues-process
- https://github.com/apache/airflow/issues/47971
