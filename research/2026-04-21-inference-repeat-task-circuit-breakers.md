# 2026-04-21 — inference repeat-task circuit breakers

Trigger: inference repeated `IQ-920` and `IQ-931` 3x in latest 30 iterations.

Findings (external patterns):
- Circuit breaker state machine (closed/open/half-open) is standard for stopping repeated failing calls and testing recovery with limited probes.
- Exponential backoff with full jitter reduces synchronized retry storms versus plain exponential backoff.
- Multi-window burn-rate style detection is effective for fast + slow confirmation before escalating.

Apply to inference loop:
- Open breaker on same `task_id` repeated >=3 with no net file-extension change set.
- Half-open probe only after cooldown (e.g., 20–30 min) with one forced-diversified task (different subsystem tag).
- Add jittered cooldown: `cooldown = base * 2^n + rand(0, base)` capped at 2h.
- Promote to WARNING when repeat count >=3 and no pass/code delta; CRITICAL only when compile/CI blocking evidence exists.
- Record breaker transitions in DB notes: `breaker=open|half-open|closed` for trend queries.

Sources consulted:
- Martin Fowler: Circuit Breaker pattern.
- AWS Architecture Blog: Exponential Backoff and Jitter.
- Google SRE / Cloud Monitoring: burn-rate alerting and multi-window guidance.
