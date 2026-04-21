# Repeat-task loop guardrails v39

Trigger: repeated task IDs (>=3) in recent iterations for both builder agents.

Findings:
- Use retry budgets to cap retries per window; stop retrying when exhausted.
- Apply exponential backoff with jitter to avoid synchronized retry waves.
- Gate retries by idempotency + transient-error class only.
- Add circuit-breaker states (closed/open/half-open) with failure-rate thresholds.
- Add no-progress fingerprinting: if same task+diff signature repeats N times, force diversification task selection.

Actionable controls for loops:
- Budget: max 2 retries per task in 30 min window.
- Backoff: base 30s, factor 2, full jitter, max 20m.
- Breaker: open after >=50% failures on last 10 attempts; half-open after cooldown.
- Diversify: inject alternate queue band + dependency/diagnostic task after 3 repeats.

Sources:
- https://sre.google/sre-book/addressing-cascading-failures/
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://resilience4j.readme.io/docs/circuitbreaker
- https://docs.cloud.google.com/storage/docs/retry-strategy
