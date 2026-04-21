# Repeat-task streak guardrails (v23)

Trigger: modernization `CQ-877` repeated 4x, inference `IQ-878` repeated 3x in recent 120 iterations.

Findings (web):
- Add explicit progress heartbeats and fail fast when heartbeat TTL expires; Temporal recommends short heartbeat timeouts for long-running work to detect worker failure quickly.
- Enforce capped retries with backoff ceilings; Kubernetes Jobs use `backoffLimit` and failure policy to stop infinite retry loops.
- Use exponential backoff + jitter to avoid synchronized retry storms and cascading failures (AWS Builders' Library + Google retry guidance).
- Retry only idempotent checkpoints; non-idempotent steps require compensation/rollback guards before automatic retry.
- Add a stall breaker: after 3 repeated task IDs with no file-level delta, auto-split scope or requeue a narrower subtask.

Suggested local policy:
1) streak>=3 and no non-doc delta => auto WARNING + research hook
2) streak>=5 => force task decomposition + new acceptance predicate
3) require per-step artifact hash change before marking PASS

References:
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://kubernetes.io/docs/concepts/workloads/controllers/job/
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://docs.cloud.google.com/storage/docs/retry-strategy
