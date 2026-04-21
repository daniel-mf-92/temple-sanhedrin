# Repeat-task streak remediation v52

Trigger: repeated task IDs (>=3 occurrences) across modernization/inference loops.

## Findings
- Temporal guidance: pair `HeartbeatTimeout` with bounded `Start-To-Close`/`Schedule-To-Close` so stalled activity attempts fail fast instead of hanging.
- Temporal guidance: keep retries explicit and bounded; use non-retryable error types for deterministic failures to avoid pointless repeats.
- Temporal guidance: persist heartbeat details/progress checkpoints so retries resume from a known stage instead of restarting blind.
- AWS reliability guidance: retries should use capped exponential backoff + jitter to avoid synchronized retry storms and thundering-herd contention.
- AWS guidance: cap total attempts/time budget; classify transient vs persistent failures before retrying.

## Apply to temple loops
- Add streak guard: if same `task_id` appears 3 consecutive attempts with no file delta/test delta, force prompt diversification or re-queue a different task.
- Persist checkpoint metadata (`task_id`, stage, touched-file hash, test hash) in heartbeat/log payload.
- Add retry budget per task ID (max attempts/time window), then auto-escalate to Sanhedrin research mode.

## Sources
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.temporal.io/encyclopedia/retry-policies
- https://docs.temporal.io/references/failures
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/rel_mitigate_interaction_failure_limit_retries.html
