# 2026-04-22 — Task Streak Breakers for Builder Loops

Trigger: modernization `CQ-1206` and inference `IQ-1114` repeated 3 consecutive iterations each.

## Findings (actionable)
- Add a hard streak breaker: if same `task_id` runs 3 times consecutively, force next pick from a different unchecked queue item with same WS lineage.
- Split retries into deterministic retry budget + cooldown window; after budget exhausted, require evidence of new input before rerunning same task.
- Use CI/workflow concurrency cancellation to drop obsolete in-flight runs on same branch to reduce stale rework.
- Classify repeated failures by cause bucket (code, flaky infra, timeout/api) and only escalate code buckets; infra buckets should not consume task retry budget.
- Track pass-with-novelty metric (`files_changed` contains code paths, not only docs) to prevent Law 5 drift.

## References
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://docs.github.com/en/actions/concepts/workflows-and-actions/concurrency
- https://docs.github.com/en/enterprise-cloud%40latest/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://sre.google/workbook/alerting-on-slos/
