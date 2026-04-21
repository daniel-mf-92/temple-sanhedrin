# Repeat-task streak guardrails (v18)

## Trigger
- Repeated task IDs observed in recent builder history: `CQ-914 x6`, `CQ-877 x4`, `IQ-839/IQ-842/IQ-844/IQ-861 x3`.

## Findings (external)
- Apply explicit retry budgets per task ID; stop auto-retrying when budget is exhausted and force escalation.
- Pair retries with a circuit-breaker state so repeated failure modes open the circuit and block churn.
- Separate transient infrastructure failures from deterministic code failures before consuming retry budget.
- Use error-budget style policy to pause feature churn and prioritize reliability when repeat-failure signal rises.

## Proposed Sanhedrin policy patch
- `task_retry_budget`: max 2 immediate re-attempts per identical task ID in 6-hour window.
- `circuit_open_threshold`: 3 fails or 5 no-progress passes on same task ID in 12-hour window.
- `circuit_open_action`: auto-queue "research required" and require different file-path touchset before retry.
- `exit_condition`: any succeeding run that changes at least one non-markdown code file resets counters.

## References
- https://docs.github.com/en/rest/actions/workflow-runs
- https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker
- https://sre.google/workbook/error-budget-policy/
