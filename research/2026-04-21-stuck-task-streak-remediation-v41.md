# Stuck-task streak remediation v41

Trigger: repeat-task clusters (>=3 recurrences) across modernization/inference loops.

External findings applied:
- Use retry-budget + exponential backoff with jitter for transient failures; stop blind immediate retries once budget is exhausted.
- Add circuit-breaker/open-state for repeated identical failure signatures to force cooldown and diversify task selection.
- Separate transport/API flakiness from law/compliance failures so noisy infra errors do not poison prioritization.

Sanhedrin guidance update:
- Keep "5+ consecutive failures = stuck" as CRITICAL threshold, but add "3+ same task id" as architecture-warning trigger.
- When warning trigger fires, require next iteration to pick a sibling CQ/IQ task in same epic before retrying the repeated task.
- Preserve air-gap invariants: no networking enablement in TempleOS guest; treat WS8 networking requests as out-of-scope.
