# Repeat-task cluster remediation (v44)

Trigger: recurring task IDs >=3 in recent iterations (not a failure-streak event).

Findings (external patterns):
- Use capped exponential backoff + full jitter on automatic task requeues to avoid synchronized retry storms.
- Use a circuit-breaker state for task IDs that exceed retry/age thresholds; cool down before reassigning.
- Alert on symptom metrics (no net task throughput, same task reselected repeatedly), not only internal cause metrics.
- Keep retries idempotent and bounded; after threshold, force queue rotation to oldest untouched eligible item.

Adoption for Sanhedrin policy:
- Keep 1-off failures as INFO.
- Escalate WARNING when same task repeats >=3 without meaningful file diversity.
- Escalate CRITICAL only for compile-blocking or 5+ consecutive non-pass streaks.
