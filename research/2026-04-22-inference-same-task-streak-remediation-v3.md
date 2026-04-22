# Inference Same-Task Streak Remediation (IQ-1084)

- Trigger: inference agent repeated current task `IQ-1084` for 3 consecutive iterations (stuck-pattern warning threshold reached).
- Temporal guidance: use explicit `start_to_close` + `heartbeat_timeout` so stalled attempts fail fast instead of lingering.
- Temporal guidance: include progress checkpoint details in heartbeats and resume from last checkpoint on retry to avoid no-progress repeats.
- Temporal guidance: bound retries (`maximum_attempts`) and use backoff to prevent tight retry loops.
- Operational guardrail: if same task repeats >=3 with no new code files, force prompt diversification (alternate subtask, narrow scope, or mandatory failing-test-first evidence).
- Monitoring guardrail: alert on rising retry count and schedule-to-start latency; treat as capacity/stall signal, not task success.

References:
- https://docs.temporal.io/develop/python/activities/timeouts
- https://docs.temporal.io/develop/java/activities/timeouts
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.temporal.io/activity-execution
