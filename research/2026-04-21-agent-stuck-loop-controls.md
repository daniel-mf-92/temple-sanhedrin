# Agent loop anti-stall controls (2026-04-21)

Trigger: repeated task IDs in recent iterations (>=3 occurrences) without failure streak.

## Findings
- Google SRE guidance supports alerting on sustained bad windows instead of single events; use consecutive-window thresholds to reduce noise.
- AWS Builders' Library recommends bounded retries with exponential backoff + jitter to avoid retry storms.
- Azure Architecture Circuit Breaker guidance recommends stopping retries when faults are likely persistent and only probing recovery after cooldown.

## Applied guardrails for Sanhedrin audits
- Keep failure severity by streak length (single=info, repeated=warning, 5+=stuck/research).
- Add task-cycle detector: same task >=3 in recent window triggers research note and recommendation.
- Keep retry budgets bounded and cooldown-aware in loop scripts; avoid unbounded rapid retry policies.

## Sources
- https://sre.google/workbook/alerting-on-slos/
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker
