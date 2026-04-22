# Repeat-task streak breakers (v61)

Trigger: same-task streaks reached 3x in recent window (`CQ-1098`, `IQ-1014`).

Findings (web):
- Add capped exponential backoff + jitter between retries to prevent synchronized retry storms.
- Use a circuit-breaker state for repeated identical failures; stop hot-looping and require cool-down.
- Disable retries when dependency is consistently failing; switch to diagnose/observe mode.
- Keep retries idempotent and bounded; do not convert transient retry logic into endless replay.

Agent-loop application:
- After same `task_id` appears 3x with low delta, force task diversification for next 2 iterations.
- If 5 consecutive failures occur, auto-open research gate and pause same-task reuse.
- Record breaker transitions in DB notes for observability.

Sources:
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://aws.amazon.com/builders-library/dependency-isolation/
- https://sre.google/sre-book/addressing-cascading-failures/
- https://martinfowler.com/bliki/CircuitBreaker.html
