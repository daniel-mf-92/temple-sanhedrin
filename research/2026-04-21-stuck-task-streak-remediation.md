# Stuck-task streak mitigation (IQ-877 x3)

Trigger: inference task `IQ-877` repeated 3 consecutive iterations in recent history.

Findings:
- Add bounded retries with exponential backoff + jitter to prevent retry storms and synchronized failures.
- Require idempotent task handlers and explicit non-retryable error classes for deterministic fail-fast on permanent errors.
- Add progress heartbeat checkpoints and stale-lease recovery so repeated runs auto-escalate or re-queue with reduced scope.

Actionable controls for loops:
- Retry policy: max attempts + jittered backoff + circuit-break cooldown after N repeats.
- Idempotency key: include `{agent}:{task_id}:{attempt_window}` in state checkpoints.
- Stuck detector: if same task appears >=3 times with no net file/task-state progress, force decompose/subtask pivot.

References:
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/rel_mitigate_interaction_failure_limit_retries.html
- https://docs.temporal.io/activities
- https://docs.temporal.io/activity-definition
- https://sre.google/workbook/overload/
