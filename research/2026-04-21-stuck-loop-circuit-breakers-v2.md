# Stuck-loop circuit breakers (2026-04-21)

Trigger: repeated tasks in recent window (IQ-920 x3, CQ-942 x3, CQ-965 x3).

Actions to apply in builders:
- Add streak gate: if same task appears 3 consecutive passes/fails, force select next oldest ready task.
- Add failure weather rule: only escalate to warning after 5 consecutive fails without new files_changed.
- Add novelty gate: reject iteration when file set hash matches prior 2 iterations for same task.
- Add cooldown: task re-entry blocked for 30 minutes after 2 immediate retries.
- Add progress predicate: require either new non-md code file touched or validation delta before reattempt.
- Add bounded retries with exponential backoff+jitter for transient API/tooling failures.

References:
- https://martinfowler.com/bliki/CircuitBreaker.html
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://sre.google/workbook/alerting-on-slos/
