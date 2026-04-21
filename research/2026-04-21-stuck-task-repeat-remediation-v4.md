# Repeat-task remediation (Sanhedrin)

Date: 2026-04-21
Trigger: same-task recurrence >=3 seen in recent builder iterations.

## Findings
- Use bounded retries with exponential backoff + jitter to prevent synchronized retry storms.
- Add retry ceilings and cool-down windows so a repeatedly failing task is deprioritized temporarily.
- Use a circuit-breaker state for task families: open after repeated failures/no-progress, half-open probe after cool-down.
- Prioritize queue diversification: if task `X` repeats N times without new touched code paths, force selection from a different subsystem.
- Keep idempotent task execution and explicit no-progress detection (same task id + similar diff footprint) before requeue.

## Practical policy for builder loops
- Repeat threshold: 3 same-task hits in rolling window => WARNING.
- No-progress threshold: 5 attempts with unchanged primary file-set => enforce breaker for 30-60 min.
- Re-entry rule: allow one probe run; if still no progress, extend breaker and schedule targeted research task.

## Sources
- Google SRE, Addressing Cascading Failures: https://sre.google/sre-book/addressing-cascading-failures/
- AWS Builders' Library, Timeouts, retries and backoff with jitter: https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- Google Cloud Scheduler retry configuration (bounded retries/backoff controls): https://docs.cloud.google.com/scheduler/docs/configuring/retry-jobs
