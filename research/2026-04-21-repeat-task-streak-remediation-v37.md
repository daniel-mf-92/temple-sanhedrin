# Repeat-task streak remediation v37

Trigger: repeated task IDs (>=3) across builder agents, despite overall pass status.

Research-backed controls:
- Add per-task retry budget (max 2 immediate retries per task ID per 2h window), then force queue advance.
- Use exponential backoff + jitter between retries to prevent synchronized retry storms.
- Add a circuit-breaker rule: if same task ID fails/loops N times, open breaker and cool down before re-entry.
- Prefer degraded fallback progress (adjacent small task) over hard repeats when overload/timeouts occur.
- Track and cap retry amplification ratio (retry_ops / total_ops) to keep recovery load bounded.

Suggested thresholds for loops:
- WARNING at 3 repeats of same task ID in recent 200 iterations.
- CRITICAL at 5 consecutive fails for same task ID with no code-file delta.
- Cooldown: 20-30 minutes before same task ID can re-enter active slot.

References:
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://sre.google/sre-book/handling-overload/
- https://martinfowler.com/bliki/CircuitBreaker.html
