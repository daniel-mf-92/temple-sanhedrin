# Stuck-loop remediation (v35)

Trigger: repeated task reuse pattern (>=3 in recent80).

Actions to apply in loop controllers:
- Add a circuit-breaker for task IDs: if same task appears 3x, force alternate task class for next 2 iterations.
- Use exponential backoff + jitter for retries/timeouts to avoid synchronized repeat storms.
- Add novelty gate: reject queue entries with >0.9 similarity to last 20 accepted tasks.
- Add progress guardrail: if no code/spec delta in 2 iterations, auto-escalate to research mode.
- Keep explicit failure budgets (single failures informational; 5+ consecutive failures = stuck).

References:
- https://martinfowler.com/bliki/CircuitBreaker.html
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://sre.google/sre-book/addressing-cascading-failures/
- https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/rel_mitigate_interaction_failure_limit_retries.html
