# Repeat-task streak guardrails (v19)

## Trigger
- Repeated task IDs in recent builder window: `CQ-914 x3`, `IQ-877 x3`.

## Findings (external)
- Enforce bounded retry budgets per task key; escalate after budget exhaustion instead of silent re-run.
- Use circuit-breaker behavior on repeated no-progress attempts to prevent churn.
- Treat consecutive-failure streaks as reliability-budget consumption and gate new work until recovery.
- Require changed touchset (different code paths) before retrying same task ID after breaker opens.

## Proposed Sanhedrin policy patch
- `retry_budget`: max 2 immediate retries per identical task ID per 6h.
- `stuck_threshold`: 3 consecutive same-task outcomes without new non-markdown code.
- `breaker_action`: force research note + alternative-file-path attempt before next retry.
- `reset_rule`: any pass that touches non-markdown code resets streak counters.

## References
- https://openai.github.io/openai-guardrails-python/examples/
- https://sre.google/workbook/error-budget-policy/
- https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
