# Repeat-task streak circuit breakers (Sanhedrin)

Trigger: repeated-task clusters detected in central DB (modernization CQ-1162 x4, inference IQ-1070 x3 in latest 12 rows).

## Practical controls to apply in loop prompts/automation
- Add hard cap on same `task_id` (max 2 consecutive attempts), then force task rotation.
- Introduce retry budgets with exponential backoff + jitter for transient infra/API failures.
- Route repeated failures to a quarantine lane (dead-letter style) for offline triage, not immediate re-run.
- Track dequeue/retry counters per task and escalate severity only when threshold breached.
- Distinguish transient failures from deterministic code failures before re-queueing.

## Why this maps to observed weather
- Current loops show pass-heavy execution, but local clustering by task indicates optimization myopia risk.
- Circuit-breaker + DLQ-style handling reduces thrash while preserving throughput on healthy tasks.

## References
- https://docs.cloud.google.com/tasks/docs/configuring-queues
- https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html
- https://learn.microsoft.com/en-us/dotnet/api/azure.storage.queues.models.queuemessage.dequeuecount?view=azure-dotnet
