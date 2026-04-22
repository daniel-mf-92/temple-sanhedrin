# Repeat-task streak guardrails (v67)

Trigger: builder task IDs repeated 3+ times in a short window.

Findings:
- Use explicit retry budget and stop-condition after N identical task repeats.
- Re-run failed jobs first instead of full workflow reruns.
- Apply circuit-breaker behavior after repeated identical failures.
- Track streak and burn-rate as escalation signals.

References:
- https://docs.github.com/en/actions/managing-workflow-runs-and-deployments/managing-workflow-runs/re-running-workflows-and-jobs
- https://martinfowler.com/bliki/CircuitBreaker.html
- https://sre.google/sre-book/operational-overload/
