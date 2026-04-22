# Research: inference task repetition (IQ-1014 repeated 3x)

Trigger: repeated same task in recent loop history indicates local stuck pattern.

Findings (actionable):
- Add explicit trial memory: carry forward a short "last 2 failed attempts + delta plan" block before retrying same task.
- Enforce max retry budget per task (e.g., 2) then force task switch to an adjacent queue item to restore throughput.
- Require ReAct-style evidence step: each retry must include one new observation (test/log/diff fact), otherwise block retry.
- Use Self-Refine two-step loop (feedback then refine) with a hard stop when feedback is unchanged across two attempts.
- Store Reflexion-style post-mortem note keyed by task_id and consult it before selecting next task.

Suggested Sanhedrin policy:
- WARNING at 3 consecutive identical task_id.
- CRITICAL at 5 consecutive failures on same task_id.
- Auto-trigger research note and DB `research` insert at first WARNING.

Sources:
- https://arxiv.org/abs/2210.03629
- https://arxiv.org/abs/2303.17651
- https://arxiv.org/abs/2303.11366
