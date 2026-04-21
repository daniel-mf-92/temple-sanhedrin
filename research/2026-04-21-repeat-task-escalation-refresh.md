# Repeat-task escalation refresh (Sanhedrin)

Trigger: repeated task IDs (>=3/hour) across builders, notably CQ-914 and IQ-960 clusters.

Findings (quick):
- Use retry budgets: cap attempts per task window; after budget exhaustion, force task rotation.
- Use circuit-breaker behavior: open breaker on repeat-no-progress patterns, then cool-down before re-entry.
- Use outcome-based alerts (not single failures): escalate only when repeated non-progress is sustained.
- Keep failure classification strict: API/timeouts are transient; only repeated no-progress indicates stuck behavior.
- Require progress-proof fields in notes (new test case, new code path, or new invariant) before allowing same task retry.

References:
- https://martinfowler.com/bliki/CircuitBreaker.html
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://sre.google/resources/book-update/practical-alerting/
