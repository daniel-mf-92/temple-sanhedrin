# Retry-loop guards for repeated task churn

Trigger:
- modernizer repeated task IDs in recent window (e.g., CQ-1223 x5)
- inference repeated task IDs (e.g., IQ-1137 x3)
- repeated LAW-4 compounding detections for same TempleOS SHA in enforcement log

Findings (external):
- Use capped exponential backoff with jitter to avoid synchronized retry storms.
- Distinguish transient vs permanent failures; retry only transient classes.
- Apply idempotency gates before retrying stateful operations.
- Open-circuit repeated failing paths and require cooldown/probe before re-entry.

Applied to Trinity loops:
- Add per-task retry budget (max attempts per task_id per N iterations) with cooldown.
- Classify LAW-4 compounding as permanent-for-that-change until naming is revised.
- Add "same SHA + same violation" suppression window to avoid repeated churn logs.
- Escalate to manual queue intervention when same task_id repeats >=3 with no diff-shape change.

References:
- Google SRE: Addressing Cascading Failures
- AWS Prescriptive Guidance: Retry with backoff pattern
- Google Cloud retry strategy guidance (idempotency + backoff)
- Martin Fowler: Circuit Breaker
