# Repeat-task recovery refresh (IQ-960)

- Trigger: inference repeated `IQ-960` 4x in recent window with minimal task diversification.
- Add per-loop retry budget and cap retries per task streak.
- Use exponential backoff + jitter for transient failures; stop retries once budget is exhausted.
- Open a circuit breaker after repeated same-task attempts and force task rotation for N loops.
- Require progress proof before re-attempting same task (new file delta or new failing test signature).

## Sources
- https://sre.google/sre-book/addressing-cascading-failures/
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html
- https://docs.aws.amazon.com/sdkref/latest/guide/feature-retry-behavior.html
- https://martinfowler.com/bliki/CircuitBreaker.html
