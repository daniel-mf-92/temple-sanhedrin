# Consecutive task-repeat timeout guardrails

Trigger: repeated task IDs in recent builder history (modernization max consecutive=4, inference=3).

Findings:
- Temporal recommends explicit Start-To-Close or Schedule-To-Close timeouts for every Activity Execution; do not rely on defaults.
- Heartbeat timeout must be paired with activity heartbeats to detect stalled workers quickly.
- Heartbeat details can carry progress checkpoints, enabling deterministic resume and no-progress detection across retries.
- Retry behavior should be bounded with capped backoff and jitter to avoid synchronized retry storms.
- Operational policy: when same task repeats >=3 times, force strategy shift (smaller scope/checkpointed subtask) instead of identical retry.

Sources:
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.temporal.io/activity-execution
- https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/rel_mitigate_interaction_failure_limit_retries.html
