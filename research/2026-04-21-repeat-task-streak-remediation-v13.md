# Repeat-task streak remediation v13 (Sanhedrin)

Trigger:
- Last 6h task repetition clusters detected (>=3 repeats): modernization `CQ-914 x6`; inference `IQ-878 x5`.
- Consecutive failure streaks are 0/0 (not failing, but loop diversity is degraded).

External findings (applied to builder loops):
- Use capped exponential backoff **with jitter** to prevent synchronized retry storms.
- Retry only transient classes; stop blind retries for deterministic failures.
- Enforce retry budgets and attempt ceilings to preserve throughput for fresh tasks.
- Add load-shedding behavior: when queue head repeats too often, temporarily deprioritize it and promote next eligible task.

Implementation policy to enforce in audits:
- If same `task_id` repeats >=3 in 6h, flag `WARNING` and require cooldown before reselection.
- If same `task_id` repeats >=5 in 6h or consumes >=40% of recent agent cycles, mandate branch-to-adjacent-task fallback.
- Keep transient API timeout failures as INFO unless 5+ consecutive non-pass without progress.

References:
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://sre.google/sre-book/addressing-cascading-failures/
- https://docs.cloud.google.com/storage/docs/retry-strategy
