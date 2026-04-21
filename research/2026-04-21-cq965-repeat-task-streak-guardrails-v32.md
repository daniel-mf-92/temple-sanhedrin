# CQ-965 repeat-task streak guardrails (v32)

Trigger: modernization repeated `CQ-965` 3 consecutive iterations.

Findings:
- Use retry budgets and fail-fast thresholds to stop unbounded retry churn after repeated failures.
- Use circuit-breaker style cooldowns after N repeated same-task attempts to force diversification.
- Use explicit `max_turns` / iteration caps for agent loops and treat cap hits as a handoff condition.
- Prefer symptom-first alerts (streak + no artifact novelty) over noisy cause-level alerts.

Applied policy update for audit judgment:
- Same-task streak >=3 with low artifact novelty => WARNING + research log.
- Same-task streak >=5 or fail streak >=5 => STUCK, mandatory deeper intervention.

References:
- https://sre.google/sre-book/addressing-cascading-failures/
- https://sre.google/workbook/alerting-on-slos/
- https://martinfowler.com/bliki/CircuitBreaker.html
- https://openai.github.io/openai-agents-python/ref/run/
