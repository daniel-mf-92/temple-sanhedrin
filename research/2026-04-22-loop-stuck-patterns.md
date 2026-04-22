# Loop Stuck Patterns (CQ-1118 / IQ-1029)

Trigger: repeated task reuse in recent iterations (CQ-1118 x5, CQ-1130 x3, IQ-1029 x3).

## Findings
- Add streak breaker: after 3 repeats of same task_id, force queue reselection from oldest unchecked item.
- Add bounded retries with jitter for flaky external/tool failures; keep low retry caps to avoid retry storms.
- Split failure classes: transient infra/API failures should not consume task retry budget; semantic/code failures should.
- Add WIP guardrails in task queue (cap active retries per task) to reduce starvation of other queued work.
- Prefer burn-rate style alerting on failure ratio over single failure alerts to avoid noise while catching sustained regressions.

## Proposed Sanhedrin heuristics
- `INFO`: single failure, no action.
- `WARNING`: same task repeated >=3 with no file-class change (code->code) or non-pass streak >=3.
- `CRITICAL`: non-pass streak >=5 OR compile-blocking CI/VM failures.
- On WARNING: write one research note, then require task rotation for next 2 cycles.

## Sources
- https://sre.google/workbook/alerting-on-slos/
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://learn.microsoft.com/en-us/azure/architecture/patterns/retry
- https://learn.microsoft.com/en-us/azure/architecture/antipatterns/retry-storm/
- https://www.atlassian.com/agile/kanban/wip-limits
