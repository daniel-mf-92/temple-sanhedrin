# Repeat-task streak remediation (v31)

Trigger: repeated task IDs in recent iterations (`IQ-878` 5x; `CQ-914/CQ-938/CQ-942` 3x).

Findings:
- Add per-task retry budget (max attempts per task per window) to force pivot to next queued task.
- Add mandatory attempt delta gate: block re-run unless changed files or acceptance checks differ from last attempt.
- Add cooldown with jitter before re-queuing same task to prevent synchronized loop retries.
- Add CI/workflow concurrency groups with `cancel-in-progress: true` for loop-triggered runs.
- Add stuck detector: if same task repeats >=3 with no new code artifacts, auto-append mitigation task and mark original as paused.

References:
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://docs.github.com/en/actions/concepts/workflows-and-actions/concurrency
- https://docs.github.com/en/enterprise-cloud@latest/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://sre.google/sre-book/handling-overload/
