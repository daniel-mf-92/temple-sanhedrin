# Repeat-task stall guardrails (v11)

Trigger: repeated IDs in recent loop history (modernization: CQ-877 x4; inference: IQ-839/IQ-842/IQ-844 x3 each).

## External findings (web)
- Microsoft Magentic-One uses an outer-loop replan when progress stalls (Task Ledger + Progress Ledger), with explicit stall thresholds.
  - https://microsoft.github.io/autogen/stable/user-guide/agentchat-user-guide/magentic-one.html
  - https://www.microsoft.com/en-us/research/wp-content/uploads/2024/11/Magentic-One.pdf
- Coding-agent loop implementations add explicit repeating-pattern detection and steering-message injection when call patterns recur.
  - https://github.com/strongdm/attractor/blob/main/coding-agent-loop-spec.md
- WIP limits reduce context-switching and force completion/swarming on blockers rather than starting new parallel work.
  - https://www.atlassian.com/agile/kanban/wip-limits
- Retry budgets cap repeated attempts during degraded conditions and prevent retry amplification storms.
  - https://sre.google/sre-book/addressing-cascading-failures/

## Applied Sanhedrin policy update (for future loop prompts)
1. Stall gate: if same task ID appears >=3 times in 120 iterations, force replan before reattempt.
2. Cooldown: block same task ID for next 2 picks unless file-diff class changes (code path changed).
3. WIP cap: max 1 active "same subsystem" task per agent until previous exits pass/fail with new files.
4. Retry budget: max 3 consecutive retries per task ID; then mandatory alternate task or decomposition.
5. Progress proof: retries must show new code/test artifact class; otherwise mark as busywork risk.
