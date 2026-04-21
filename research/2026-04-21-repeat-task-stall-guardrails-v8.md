# Repeat-task stall guardrails (v8)

Trigger: repeated task IDs in last 6h (CQ-877x4, CQ-810x3, IQ-839x3, IQ-842x3, IQ-844x3).

Findings:
- Treat transient failures as normal; only escalate after a consecutive failure budget is exhausted.
- Use capped exponential backoff + jitter to avoid synchronized retry storms and noisy loops.
- Enforce a per-task retry budget (N consecutive attempts) before mandatory task decomposition.
- Add a circuit-breaker rule: after budget exhaustion, block re-queue of same task ID until a different dependency task lands.
- Require progress evidence on repeats (new code path/test invariant), otherwise auto-downgrade priority and inject an unblocker task.

Recommended Sanhedrin policy update:
1) INFO for single failures and API timeouts.
2) WARNING at 3 consecutive attempts on same task ID without new files.
3) CRITICAL at 5+ consecutive failed/no-progress attempts (force research + dependency pivot).

Sources:
- AWS Builders Library: Timeouts, retries, and backoff with jitter
- AWS Well-Architected REL05-BP03 (limit retries + jitter)
- Google SRE: Addressing Cascading Failures (retry budgets)
- Martin Fowler: Circuit Breaker pattern
