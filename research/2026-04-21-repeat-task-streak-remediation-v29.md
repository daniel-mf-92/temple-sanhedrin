# Repeat-task streak remediation v29

Trigger: repeated task streaks observed (modernization `CQ-938` x3, inference `IQ-878` x3 in recent window).

## Findings (external)
- Add capped retries with exponential backoff + jitter to avoid synchronized retry storms.
- Enforce explicit retry budgets per task class and cool-down on exhausted budget.
- Reset backoff only after sustained successful run window, not single success.
- Alert on stuck symptom (same task repeated N times) and auto-switch to alternative queued task.
- Require progress signal per iteration (code-delta hash changed or test frontier changed) before allowing same task retry.

## Candidate guardrails for loops
- `repeat_task_threshold=3` in rolling 20 iterations.
- `max_same_task_attempts=4`, then quarantine task with reason code.
- `progress_token` check: block rerun if unchanged token for 2 consecutive attempts.
- `retry_delay` with jitter and hard upper bound.

## References
- https://docs.aws.amazon.com/wellarchitected/2023-04-10/framework/rel_mitigate_interaction_failure_limit_retries.html
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/
- https://cloud.google.com/blog/topics/developers-practitioners/why-focus-symptoms-not-causes
