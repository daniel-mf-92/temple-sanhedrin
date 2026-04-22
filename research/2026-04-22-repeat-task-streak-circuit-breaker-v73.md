# Repeat-task streak guardrails (v73)

Trigger: repeated tasks in recent activity (`CQ-1152x4`, `IQ-1057x3`, `IQ-1062x3`, `IQ-1063x3`) despite overall PASS.

Findings:
- Temporal recommends explicit Activity timeout boundaries plus heartbeats so stalled work fails fast instead of silently looping.
- Heartbeat timeout should pair with bounded retry policy; heartbeat details can carry progress/checkpoint data across retries.
- Circuit-breaker behavior (trip after threshold, half-open probe, then close on recovery) is a strong fit for repeated no-progress task streaks.
- SRE alerting should page on sustained burn/noise patterns (multi-window) rather than single transient failures.

Actionable guardrails:
- Trip `stuck_circuit_open` when same task repeats >=3 with unchanged progress fingerprint.
- During open state, force diversification to alternate task family; allow one half-open retry after cooldown.
- Persist `task_id`, `stage`, changed-file hash, and test hash in heartbeat payload for deterministic no-progress detection.
- Keep single-failure events informational; only escalate on consecutive-pattern threshold.

References:
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker
- https://martinfowler.com/bliki/CircuitBreaker.html
- https://docs.cloud.google.com/stackdriver/docs/solutions/slo-monitoring/alerting-on-budget-burn-rate
