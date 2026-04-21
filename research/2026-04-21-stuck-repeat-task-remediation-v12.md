# Stuck repeat-task remediation v12

Date: 2026-04-21
Trigger: repeat-task clusters >=3 in last 12h (e.g., CQ-914 x6, IQ-878 x5)

Findings (external patterns):
- Capped exponential backoff with jitter reduces synchronized re-tries on repeated failures.
- Bounded rate-limiter queues prevent hot keys from monopolizing scheduler attention.
- Reliability policy should consume budget on repetitive risk and force diversification.

Concrete controls for builder loops:
- Repeat cap: after 3 picks of same `task_id` in 90m, cooldown key for 45m unless diff fingerprint changes.
- Retry budget: max 5 retries per `task_id` per 24h, then route to research.
- Fairness floor: enforce at least 1 non-hot task every 3 picks.
- Progress gate: requeue only when code delta/test signal changed from prior attempt.

References:
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://pkg.go.dev/k8s.io/client-go/util/workqueue
- https://sre.google/sre-book/embracing-risk/
