# Stuck pattern: circuit-breaker windowing

Trigger: repeated tasks in recent window (`IQ-920`, `CQ-942`, `CQ-965` each appeared 3x).

Findings:
- Apply count-based circuit breaker at scheduler level: if same task_id appears >=3 in last 10 builder iterations, force cooldown for 2 cycles.
- Use exponential backoff + jitter for retried task picks to avoid deterministic re-selection loops.
- Alert on symptom (consecutive fail/no-progress streak) not transport noise; API timeout alone is informational.
- Add novelty constraint: next pick must differ by task prefix/WS lineage when streak detected.

Operational rule update proposal:
- WARNING at 3 repeats in rolling 20.
- CRITICAL at 5 consecutive no-progress failures.

Refs:
- https://github.com/failsafe-lib/failsafe.dev/blob/master/circuit-breaker.md
- https://dev.to/yairst/error-budget-is-all-you-need-part-2-3inb
