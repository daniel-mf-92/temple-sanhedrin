# Stuck repeat-task guardrails refresh (2026-04-21)

Trigger: repeat-task streaks (>=3 occurrences in recent 60 iterations) across both builder agents.

Findings:
- Temporal: use `HeartbeatTimeout` + bounded `StartToClose`/`ScheduleToClose` so stalled activities fail fast and retries requeue instead of hanging.
- Temporal: retries should be explicit policy, not unbounded defaults; persist heartbeat details (task/stage/progress hash) to detect no-progress retries.
- AWS retry guidance: apply capped exponential backoff with jitter; avoid synchronized retry storms.
- Circuit-breaker guidance: trip open after threshold, cool-down window, then half-open probe before full reopen.

Recommended controls for builder loops:
- Add `progress_proof` per attempt (`task_id`, touched-files hash, validation hash).
- If same `task_id` appears 3 times with unchanged `progress_proof`, force task diversification.
- If 5 consecutive fails on same task family, open circuit for that family for one scheduling window.
- Keep hard retry cap and jittered sleep between attempts.

References:
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.temporal.io/activity-execution
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/rel_mitigate_interaction_failure_limit_retries.html
- https://martinfowler.com/bliki/CircuitBreaker.html
