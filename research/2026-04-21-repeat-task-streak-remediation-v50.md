# Repeat-task streak remediation (v50)

Trigger: repeated task IDs >=3 in recent builder iterations (stuck-pattern risk).

Actions to apply in loop orchestration:
- Add per-task attempt budget (max 2 consecutive runs) then force task rotation.
- Add circuit-breaker state: open after 5 consecutive failed/no-progress attempts, cool-down one cycle.
- Add semantic progress gate: require changed code targets (e.g., `.HC`/`.sh`) before allowing same task_id retry.
- Add backoff jitter on retried tasks to reduce synchronized repeat loops.
- Emit explicit `stuck_reason` + `next_non_repeated_task` in iteration notes for auditability.

Reference domains checked: kubernetes.io, docs.aws.amazon.com, learn.microsoft.com.
