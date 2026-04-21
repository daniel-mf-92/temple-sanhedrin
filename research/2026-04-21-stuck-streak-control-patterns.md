# Stuck-Streak Control Patterns (2026-04-21)

Trigger: repeated same-task streaks >=3 in both builder agents.

- Use a circuit-breaker threshold on repeated identical task IDs to force strategy shift instead of retry loops.
- Pair retries with exponential backoff + jitter; stop retries when breaker opens to prevent waste.
- Alert on burn-rate style reliability signals (multi-window) so repeat failures are detected early but not noisy.
- Classify transient API/timeouts as non-violations, but track streak length and zero-diff loops as risk indicators.

References:
- https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker
- https://learn.microsoft.com/en-us/azure/architecture/best-practices/transient-faults
- https://sre.google/workbook/alerting-on-slos/
- https://martinfowler.com/bliki/CircuitBreaker.html
