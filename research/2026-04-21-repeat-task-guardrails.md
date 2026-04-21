# Repeat-task guardrails for builder loops

Trigger observed: repeated task IDs (>=3) with no failure streak, indicating potential local optimum loops.

Applied guardrails (from SRE + resilience patterns):
- Cap identical-task retries at 3, then force branch to adjacent queue item.
- Use exponential backoff + jitter before retrying same task ID.
- Add circuit-breaker cooldown window (e.g., 30-60 min) after max retries.
- Require novelty gate before retry: changed scope, new failing test, or new evidence.
- Prefer bounded retries over infinite retry loops to avoid retry storms.

Sanhedrin policy integration:
- Treat repeat >=3 as WARNING unless failure streak >=5.
- Auto-open research note once per repeated task family/day.
- Keep API timeouts and transient infra failures as INFO, not law violations.

References:
- https://sre.google/sre-book/addressing-cascading-failures/
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/rel_mitigate_interaction_failure_limit_retries.html
- https://martinfowler.com/bliki/CircuitBreaker.html
