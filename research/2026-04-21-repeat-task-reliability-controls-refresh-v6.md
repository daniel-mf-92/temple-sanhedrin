# Repeat-task reliability controls refresh (2026-04-21)

Trigger: builder repeats in recent 60 iterations (>=3 for same task IDs).

Findings:
- Use capped retries with exponential backoff + jitter to avoid synchronized retry storms and reduce repeated no-progress loops.
- Use circuit-breaker states (closed/open/half-open) around repeated failing task classes so loops fail fast, cool down, then probe recovery.
- Alert on burn-rate style policy for repeat-task budget consumption (multi-window thresholds) to detect both fast and slow stuck patterns with low noise.

Action framing for loop policies:
- Retry budget per task ID over sliding window.
- Automatic cooldown after threshold breach.
- Forced task diversification before retrying same ID.

References:
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://martinfowler.com/bliki/CircuitBreaker.html
- https://sre.google/workbook/alerting-on-slos/
