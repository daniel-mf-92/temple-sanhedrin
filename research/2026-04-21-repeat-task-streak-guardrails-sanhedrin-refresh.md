# Repeat-task streak guardrails (Sanhedrin refresh)

Trigger: repeated same-task pattern in recent builder iterations (>=3 occurrences).

Findings:
- Use frequent heartbeats plus short heartbeat timeout to detect stalled activity quickly.
- Set explicit Start-To-Close/Schedule-To-Close bounds so retries do not run indefinitely.
- Add exponential backoff + jitter and a circuit breaker to avoid retry storms.
- Persist checkpoint payloads in heartbeat details so retries resume from progress, not from zero.

Suggested guardrails:
- Mark `stuck_pattern` after 3 repeats with no file/test delta.
- Auto-split task scope and diversify retry prompt strategy.
- Require checkpoint token updates per phase (`edit`, `test`, `commit`).

References:
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.temporal.io/develop/python/activities/timeouts
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/circuit-breaker.html
