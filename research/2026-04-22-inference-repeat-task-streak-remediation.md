# Repeat-task streak remediation (inference)

Trigger: `IQ-1014` appeared 3 consecutive times in recent iterations (also prior 3x streaks on `IQ-1006` and `IQ-990`).

## Findings (external)
- AWS Builders Library recommends bounded retries plus exponential backoff with jitter to avoid synchronized retry storms.
- Azure Architecture pattern guidance recommends circuit-breaker states (closed/open/half-open) with thresholded failure windows.
- Google SRE practical alerting guidance emphasizes actionable symptoms and suppression of noisy/non-actionable repetition.

## Applied Sanhedrin policy update
- Escalate to WARNING when same agent repeats same `task_id` 3x consecutively without novel code-path delta.
- Escalate to CRITICAL only when compile/test outcome regresses or 5+ consecutive failures occur.
- Recommend 1-loop cool-down + forced task diversification after 3x repeat streak.
- Track novelty signal in notes (`new files/functions/invariants touched`) to distinguish progress vs churn.

## References
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker
- https://sre.google/sre-book/practical-alerting/
