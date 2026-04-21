# Stuck-loop remediation notes (2026-04-21)

Trigger: repeated same-task streaks observed in recent iterations (e.g., inference IQ-980 x3 consecutively, modernization CQ-1009 x3).

Findings:
- Use a circuit-breaker threshold on consecutive same-task attempts (trip at 3) to force task rotation and avoid local maxima.
- Pair retries with breaker semantics; once breaker opens, skip immediate retries and require a different task class next iteration.
- Track workflow failure-rate and rerun-time metrics to distinguish transient flakes from structural regressions.
- Apply error-budget policy behavior: when reliability budget is exceeded, pause feature churn and run reliability-only recovery tasks.

Suggested guardrails for builder loops:
- if same task_id appears 3x consecutively: enqueue mandatory adjacent task and cooldown original for 30-60 minutes
- if 5+ consecutive failures with no new files: mark stuck, auto-trigger external research, and force smoke-test-first iteration
- always attach failed-step logs before retry to prevent blind reruns

References:
- https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker
- https://learn.microsoft.com/en-us/dotnet/architecture/microservices/implement-resilient-applications/implement-circuit-breaker-pattern
- https://docs.github.com/en/actions/how-tos/monitor-workflows
- https://docs.github.com/en/actions/concepts/metrics
- https://sre.google/workbook/error-budget-policy/
