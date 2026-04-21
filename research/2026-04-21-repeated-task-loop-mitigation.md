# Repeated-task loop mitigation (CQ/IQ 3+ repeats)

## Trigger
- modernization: `CQ-965 x3`, `CQ-942 x3` in recent 50
- inference: `IQ-920 x3` in recent 50

## Findings (actionable)
1. Add a **circuit breaker** for task retries: after N consecutive same-task iterations, force open-circuit and route to alternative queue bucket/new task family for one cycle.
2. Use **half-open recovery**: after cooldown (e.g., 1 cycle), allow one retry of stuck task; if success, close breaker; if fail/no-delta, reopen.
3. Add **delta gate**: fail fast if proposed patch has no meaningful code delta (`.HC/.sh/.py` unchanged) to prevent pass-without-progress loops.
4. Enable **workflow concurrency cancellation** for branch loops to prioritize newest run and reduce stale queued executions.
5. Alert on **burn-rate of non-progress events** (e.g., repeated task_id + no code delta) using multi-window thresholds to catch narrow-minded loops early with low noise.

## Suggested thresholds
- `stuck_warn`: same `task_id` >= 3 in last 50
- `stuck_critical`: same `task_id` >= 5 in last 80 OR fail streak >= 5
- `no_progress_warn`: >= 3 pass rows with docs-only deltas

## Sources
- https://martinfowler.com/bliki/CircuitBreaker.html
- https://docs.github.com/en/enterprise-cloud@latest/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://sre.google/workbook/alerting-on-slos/
- https://docs.cloud.google.com/stackdriver/docs/solutions/slo-monitoring/alerting-on-budget-burn-rate
- https://arxiv.org/html/2411.13768v2
