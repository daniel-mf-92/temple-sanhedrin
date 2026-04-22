# Stuck-task thrash guardrails (CQ-1214 repeated)

Trigger: modernization head task repeated 4 consecutive iterations (`CQ-1214`) on April 22, 2026.

## Findings
- Repetition with limited state change is a known autonomous-agent failure mode; an explicit early-stop/meta-controller reduces wasted retries.
- Circuit-breaker thresholds are appropriate for repetitive near-identical attempts: trip after N repeats, require cooldown/new evidence before re-open.
- Reliability alerting should use multi-window burn-rate style detection (fast + slow windows) to catch both sudden and chronic thrash.

## Sanhedrin policy patch (operational)
- Add `same_task_head >= 3` + `same_primary_file >= 3` as `WARNING`; `>=5` as `CRITICAL` unless new code artifact class appears.
- Require evidence delta to clear warning (new HolyC path, new test signal, or CI state change).
- On trip, force research+task-rotation recommendation in DB notes.

## Sources
- https://arxiv.org/abs/2508.13143
- https://martinfowler.com/bliki/CircuitBreaker.html
- https://docs.cloud.google.com/stackdriver/docs/solutions/slo-monitoring/alerting-on-budget-burn-rate
- https://sre.google/workbook/alerting-on-slos/
