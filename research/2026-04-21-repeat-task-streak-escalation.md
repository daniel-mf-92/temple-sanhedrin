# Repeat-task streak escalation controls (Sanhedrin)

Trigger: repeated same task IDs >=3 in recent builder iterations.

## Findings applied
- Use retry budgets per task (max attempts per rolling window) to prevent infinite task cycling.
- Apply exponential backoff with jitter between retries to reduce synchronized thrashing.
- Add circuit-breaker state after N consecutive non-progress retries; require task decomposition before reopen.
- Classify repeated failures by impact: INFO (single), WARNING (repeated without progress), CRITICAL (compile/boot blocking).
- Require post-incident capture for streaks crossing threshold with concrete remediation action and owner.

## Practical policy for loops
- Consecutive attempts per task ID: hard cap 3 before forced reframe.
- Cooldown: 5-15 min jittered delay on retries.
- Reopen gate: only if new hypothesis or changed file scope is present.
- Escalate to research path at streak >=3; escalate to CRITICAL only when compile/runtime blocked.

## Sources
- https://sre.google/workbook/error-budget-policy/
- https://sre.google/workbook/alerting-on-slos/
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/rel_mitigate_interaction_failure_limit_retries.html
- https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-61r3.pdf
