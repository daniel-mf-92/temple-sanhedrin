# Repeat-task streak remediation (v33)

Trigger: recent builder stream shows repeated task IDs (>=3), indicating potential local minima.

- Cap retries and add exponential backoff + jitter to prevent synchronized non-progress retry storms.
- Add a circuit-breaker state: after N repeated non-progress attempts, force cooldown and alternate tactic.
- Separate transient from persistent faults; persistent faults should trip the breaker and rotate strategy.
- Enforce progress delta per retry (new file scope, new failing signature, or new assertion path).

Sources:
- https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
