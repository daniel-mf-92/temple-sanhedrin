# Repeat-task circuit breaker + WIP guardrails

Trigger: repeated same task IDs (modernization max consecutive same task=3; inference max consecutive same task=3).

Findings:
- Use a task-level circuit breaker: if the same task fails or repeats beyond threshold, pause that task and force queue advance.
- Cap retries (2-3) and add jittered backoff to avoid synchronized retry storms that waste cycles.
- Enforce idempotent retry semantics so retried attempts cannot duplicate side effects.
- Apply explicit WIP limits per agent loop (e.g., one active repeat candidate at a time) so loops finish-before-start and reduce churn.
- Add error-budget style policy: when repeat/stall budget is exhausted, freeze feature churn and spend one cycle on unblock/reliability actions.

References:
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://martinfowler.com/bliki/CircuitBreaker.html
- https://sre.google/workbook/error-budget-policy/
- https://www.atlassian.com/agile/kanban/wip-limits
