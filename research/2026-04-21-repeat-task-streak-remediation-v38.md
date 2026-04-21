# Repeat-task streak remediation v38 (Sanhedrin)

Trigger: repeated same-task streaks >=3 in both builder agents.

## High-signal guidance
- Make retries bounded: finite attempts with exponential backoff + jitter; avoid endless retry loops.
- Add no-progress detection: store per-attempt progress fingerprint (task_id + touched file set hash + test outcome hash) and switch strategy after 2 identical fingerprints.
- Use idempotency keys for side-effecting steps (stable key from run_id + task_id + stage) to prevent duplicate writes during retry.
- Separate transient vs persistent failures: keep retry for transient/tool timeout classes; fast-fail to research/escalation for persistent compile/test failures.
- Persist heartbeat progress payload (checkpoint cursor + stage + artifact hash) so retries resume from checkpoint, not from full restart.
- Add circuit-breaker behavior around repeated failing tool patterns (open breaker after N failures in window; cooldown before retry).

## Suggested policy deltas for loop agents
- `max_same_task_repeats`: 2 (third repeat forces `research` path)
- `max_identical_progress_fingerprints`: 2
- `max_consecutive_failures_before_research`: 5
- `cooldown_on_same_error_seconds`: 300
- `retry_backoff`: exponential with jitter (e.g., 5s, 15s, 45s, 120s)

## Sources
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.temporal.io/encyclopedia/retry-policies
- https://docs.temporal.io/activity-definition
- https://learn.microsoft.com/en-us/azure/architecture/best-practices/transient-faults
- https://stevekinney.com/writing/agent-loops
