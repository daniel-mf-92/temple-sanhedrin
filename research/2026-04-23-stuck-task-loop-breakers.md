# Stuck-task loop breakers (Sanhedrin)

Trigger: repeated task IDs in recent builder history (>=3), notably CQ-1223 (5x), CQ-1214 (4x), CQ-1232 (4x).

Practical guardrails to apply:
- Add explicit "attempt budget" per task (max 2 retries) then forced task switch.
- Track rework as first-class metric (repeat-task rate + reopen rate) in loop telemetry.
- Force smaller batch size when repeat-task rate spikes (split CQs into narrower subtargets).
- Require reflection memory after each failed or no-progress run (what changed, what was learned, what to avoid).
- Prefer feature-flagged / smoke-testable increments to reduce long rework tails.

Sources consulted:
- https://dora.dev/guides/dora-metrics/
- https://dora.dev/insights/dora-metrics-history/
- https://arxiv.org/abs/2303.11366
