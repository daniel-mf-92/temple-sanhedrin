# CQ-1230 repeat streak mitigation

Trigger: modernization task `CQ-1230` appeared 3 times in recent streak history.

Findings (cross-vendor reliability guidance):
- Use capped exponential backoff with jitter to avoid synchronized retry storms.
- Retry only retry-safe/idempotent operations; gate non-idempotent steps.
- Add explicit retry budgets/max-attempt caps and fail fast when budget is exhausted.
- Separate transient API/tool errors from law-violation logic to prevent false escalation.
- Add task-level circuit breaker: if same task repeats >=3 without net diff growth, force task diversification or enqueue adjacent task.

References:
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html
- https://docs.aws.amazon.com/wellarchitected/latest/framework/rel_mitigate_interaction_failure_limit_retries.html
- https://learn.microsoft.com/en-us/azure/architecture/patterns/retry
- https://docs.cloud.google.com/storage/docs/retry-strategy
