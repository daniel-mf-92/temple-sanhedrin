# Stuck-pattern loop diversification (Sanhedrin)

Trigger: repeated task IDs observed in recent builder iterations.

Findings:
- Reflexion-style verbal feedback improves next-attempt performance when agents retain concise failure summaries between trials.
- ReAct-style interleaving of reasoning and actions reduces blind retry loops by forcing evidence-gathering before next edits.
- Plan-and-Solve prompting reduces missing-step failures by requiring an explicit plan before execution.

Operational guardrails for builder loops:
- After 3 repeats of the same task ID, require a one-iteration "diversify" mode: fresh hypothesis + different file surface.
- After 5 consecutive fails, enforce bounded rollback: freeze task, open sibling queue item, and return with new evidence.
- Persist a compact "last-failure cause" token in heartbeat/metadata to prevent identical retry prompts.

References:
- https://arxiv.org/abs/2303.11366
- https://arxiv.org/abs/2210.03629
- https://arxiv.org/abs/2305.04091
