# Stuck-task mitigation for builder loops (2026-04-21)

Trigger: repeated tasks in recent central DB window (inference IQ-936/IQ-944/IQ-931/IQ-946; modernization CQ-990/CQ-992 each >=3 occurrences).

Findings:
- Use bounded retries with exponential backoff + jitter to avoid synchronized retries and failure amplification (AWS Builders' Library; Google SRE cascading failures).
- Enforce retry budgets per task-id (e.g., max 2 retries before forced task rotation) to break local minima loops.
- Add circuit-breaker behavior on repeated same-task attempts: open breaker after N attempts, cooldown, require novelty signal to close.
- Require novelty guard before re-attempting same task-id: changed failing signal, new commit base, or new test evidence.
- Keep idempotent preflight checks; avoid unbounded re-run of identical failing preflight paths.

Suggested control knobs:
- retry_budget_per_task=2
- cooldown_minutes=20
- breaker_threshold_same_task=3
- novelty_required=true

Sources:
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/rel_mitigate_interaction_failure_limit_retries.html
- https://sre.google/sre-book/addressing-cascading-failures/
- https://martinfowler.com/bliki/CircuitBreaker.html
