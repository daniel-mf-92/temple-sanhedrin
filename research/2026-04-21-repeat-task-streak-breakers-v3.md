# Repeat-task streak breakers (Sanhedrin)

Trigger: repeated same-task executions (>=3) for builder loops without clear scope expansion.

## Findings
- Use symptom-based alerting: escalate only on repeated user-visible failure patterns, not single event noise.
- Add multi-window burn-rate style gates for loop health: fast gate (15-30m) + slow gate (6-24h) to catch both spikes and chronic churn.
- For repeated same-task IDs, enforce a circuit-breaker policy: after 3 repeats require task split, after 5 repeats force alternative approach or dependency unblocking.
- Prefer deterministic acceptance checks tied to one artifact change per iteration to prevent endless micro-rewrites.
- Keep failure taxonomy explicit: API/timeouts = transient (INFO), compile/test regressions = actionable (WARNING/CRITICAL).

## Applied policy update
- Keep current Sanhedrin thresholds (single failure=INFO, 5+ consecutive failures=stuck).
- Add repeat-ID guard: if same task_id appears 3+ times in rolling 120 rows, flag WARNING and require next run to change scope token (new sub-goal, file family, or test dimension).
- If same task_id reaches 5+ repeats, classify as stuck and require research + queue surgery recommendation.

## Sources
- https://sre.google/workbook/alerting-on-slos/
- https://sre.google/sre-book/monitoring-distributed-systems/
- https://martinfowler.com/bliki/CircuitBreaker.html
