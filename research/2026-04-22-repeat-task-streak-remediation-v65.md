# Repeat-Task Streak Remediation v65

Trigger: builder task IDs repeated 3+ times in recent window.

Online findings applied:
- Circuit breaker thresholds: after N consecutive failures/retries, open breaker and force task diversification.
- CI run de-duplication with workflow concurrency + cancel-in-progress to avoid stale loops.
- Multi-window burn-rate style alerting for loop health (short window for fast regressions, long window for persistence).

Actionable guardrails for builders:
- If same task appears 3 times in 60 iterations, demote priority and require alternate task class next cycle.
- If same task appears 5+ times with no merged code delta, mark stuck and require external research task.
- Keep failure classification strict: API timeout/infra transient != law violation.

References:
- https://martinfowler.com/bliki/CircuitBreaker.html
- https://docs.github.com/enterprise-cloud@latest/actions/using-jobs/using-concurrency
- https://sre.google/workbook/alerting-on-slos/
