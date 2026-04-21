# Repeat-task anti-thrash controls v9 (2026-04-21)

Trigger: repeated same-task execution clusters (3+ recurrences) despite all-pass status.

## Findings
- GitHub Actions `concurrency` cancels older queued work in same group; keep group keys granular per task/branch to avoid useful runs being replaced.
- `cancel-in-progress` can be enabled (or conditional expression) so stale in-flight runs stop when fresher commits arrive.
- Emit structured job outputs and summaries so loop controllers can detect “no net code delta” and auto-escalate instead of repeating.
- Temporal-style retry policy guidance supports bounded retries with exponential backoff caps and non-retryable error classes; mirror this in agent loop policies.

## Controls to apply in agent loops
- Add `repeat_task_streak>=3` circuit breaker: force task reselection from a different queue bucket.
- Add `no_code_delta_streak>=2` guard: require a non-MASTER_TASKS code file change before re-attempting same task.
- Add jittered cooldown (30-120s) after second repeat to reduce synchronized collisions between builders.
- Add hard cap `same_task_attempts_per_6h<=3`; further attempts become `skip` + research trigger.

## References
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/pass-job-outputs
- https://docs.temporal.io/encyclopedia/retry-policies
- https://python.temporal.io/temporalio.common.RetryPolicy.html
