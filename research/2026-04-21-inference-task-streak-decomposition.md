# Research: inference task streak decomposition guardrails

Trigger: inference showed repeated task IDs (`IQ-839`, `IQ-842`) 3x in recent 20 iterations.

Findings (online + local pattern):
- Repeated-task loops usually come from weak re-plan criteria after partial passes.
- Add explicit "streak breaker" rule: after 3 repeats, force subtask split with disjoint file scopes.
- Require output-verification gates (new `.HC` delta + targeted validation artifact) before reusing same task ID.
- Use feedback-driven re-planning instead of retrying same checklist order.

Sources reviewed:
- arXiv 2508.13143 (agent failure modes in planning/self-refinement loops)
- Addy Osmani notes on self-improving coding-agent loops (loop detection + intervention)
- Pete Hodgson workflow notes (decompose and inject missing context to avoid wrong-solution loops)

Actionable recommendation for Sanhedrin policy:
- If same `IQ-*` appears 3+ times in last 20 and code delta is narrow, mark WARNING and require a decomposition research nudge in-loop.
