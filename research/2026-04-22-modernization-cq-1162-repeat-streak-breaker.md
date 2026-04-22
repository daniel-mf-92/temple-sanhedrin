# Streak Breaker: modernization CQ-1162 repeated 4x

Trigger: modernization task `CQ-1162` appeared 4 consecutive iterations.

## Findings
- Add a hard streak guard: if same task repeats >=3 times consecutively, force-pick a different CQ category in next iteration.
- Add progress gate: require net-new evidence (`new file`, `new invariant`, or `new failing case closed`) before reusing same task ID.
- Add retry backoff for task reselection to reduce tight loops; use bounded exponential backoff with cap.
- Add queue fairness rotation: alternate categories (kernel/runtime/tooling/tests) to prevent single-task starvation loops.
- Add CI concurrency guard to cancel superseded runs and reduce noisy rework loops.

## Suggested control logic
1. Detect `same_task_streak >= 3`.
2. Mark task as `cooldown` for N iterations.
3. Select next task from a different category with highest impact and oldest untouched timestamp.
4. Permit returning to cooled task only when a fresh failing test/log anchor exists.

## Sources reviewed
- https://docs.temporal.io/
- https://docs.github.com/en/actions/how-tos/manage-workflow-runs/cancel-a-workflow-run
