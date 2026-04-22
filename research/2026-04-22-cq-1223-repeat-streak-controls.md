# CQ-1223 repeat streak controls (trigger: same task 3+ times)

## Trigger observed
- modernization head task streak reached 3 consecutive iterations on `CQ-1223`.

## Findings
- Use retry budgets and backoff/jitter to prevent tight retry loops when a step keeps failing transiently.
- Add workflow concurrency guards so stale in-flight runs are canceled and only newest work proceeds.
- Enforce explicit progress evidence per iteration (new code path/test/assertion), else force task rollover/escalation.
- Introduce automatic stale-task guardrail: after 3 same-task iterations, require split into a bounded subtask or escalate.

## Recommended guardrails for builder loops
- Add per-task consecutive counter persisted in loop state; threshold `3` triggers `RESEARCH_REQUIRED` and blocks same task reuse without new acceptance criterion.
- Require a changed-artifact class delta across repeats (e.g., code + test, not same wrapper-only edits repeatedly).
- Add cooldown for repeated task IDs (e.g., 2 iterations) unless previous run changed failing evidence fingerprint.

## Sources
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html
- https://docs.github.com/en/actions/using-jobs/using-concurrency
- https://sre.google/sre-book/monitoring-distributed-systems/
