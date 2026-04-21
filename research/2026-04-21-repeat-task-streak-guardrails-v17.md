# Repeat-task streak remediation v17

Trigger: builder task repeated 3+ consecutive times.

Findings (web):
- Use idempotency keys and dedupe at consumer boundary.
- Split transient vs permanent failure classes; retry transient only.
- Use exponential backoff with jitter to prevent retry storms.
- Cap retries and route no-progress tasks to dead-letter workflow.
- Use lease/TTL and heartbeat for stale in-flight recovery.
- Trigger early-stop and forced re-plan on repeated same-task loops.

Operational guardrails:
1) Same task_id 3x consecutively => force dequeue and select next eligible task.
2) Cooldown per task_id before same-agent retry.
3) Require changed artifact fingerprint before same-task retry.
4) After retry cap, auto-create unblock/research task and mark original blocked.
5) Store retry reason code for pattern analytics.

Sources:
- https://martinfowler.com/articles/bottlenecks-of-scaleups/05-resilience-and-observability.html
- https://stripe.com/blog/idempotency
- https://arxiv.org/html/2508.13143v1
