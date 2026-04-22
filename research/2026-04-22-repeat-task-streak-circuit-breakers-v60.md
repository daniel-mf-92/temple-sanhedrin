# Repeat-task streak circuit breakers (v60)

Trigger: inference repeated `IQ-1014` 3x and modernization repeated `CQ-1098` 3x in recent window.

Findings:
- Temporal recommends heartbeats for long activities and explicit timeout bounds (`heartbeatTimeout`, `startToClose`, or `scheduleToClose`) so stalled work fails fast instead of silently hanging.
- Temporal retry defaults can be effectively unbounded (`maximumAttempts=0`), so stuck task loops need explicit max attempts + dead-letter/escalation after cap.
- Temporal backoff defaults (initial 1s, coefficient 2.0, max interval 100s) should be paired with task-diversification after repeated identical task IDs.
- Temporal TS ActivityOptions explicitly call out heartbeat requirement for long-running activities; this matches observed loop behavior risk.
- AWS Builders Library recommends timeouts + exponential backoff + jitter to avoid synchronized retries and repeated no-progress storms.

Recommended guardrails for the loops:
- After 3 identical task IDs in rolling window, force queue diversification to a different task family before allowing same ID again.
- After 5 identical task IDs OR unchanged artifact hash across retries, emit `WARNING` and inject research task automatically.
- Cap same-task retries with hard ceiling and write terminal state to DB for human intervention.
- Add jitter to reschedule sleep and include progress fingerprint (`task_id`, file hash, validation hash) in heartbeat payload.

References:
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.temporal.io/encyclopedia/retry-policies
- https://typescript.temporal.io/api/interfaces/common.ActivityOptions
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
