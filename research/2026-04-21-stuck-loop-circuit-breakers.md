# Stuck-loop circuit breakers (Sanhedrin)

Trigger: repeated task IDs in recent 50 iterations (`IQ-878` x5, `IQ-920` x3, `CQ-965` x3, `CQ-942` x3, `CQ-938` x3).

## Findings (apply to both builder loops)
- Add hard repeat guard: if same task ID appears 3 times in rolling 20, force task reselection from top 10 backlog candidates.
- Add failure weather rule: only escalate to WARNING at 5+ consecutive fails with no new code/spec artifact.
- Add stagnation guard: if 3 passes in a row touch only docs/metadata, force next iteration to be code/spec/test artifact.
- Add cool-down lock: block a repeated task ID for 45-60 minutes after 2 immediate retries.
- Add outcome gate: require each pass to emit one of {`.HC`, `.sh`, `.py`, concrete spec delta}; else mark iteration `skip` not `pass`.

## External references
- https://martinfowler.com/bliki/CircuitBreaker.html
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://sre.google/resources/practices-and-processes/incident-management-guide/
