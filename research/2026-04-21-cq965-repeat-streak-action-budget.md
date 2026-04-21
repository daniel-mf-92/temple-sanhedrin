# CQ-965 repeat streak (3x) — action-budget guard

Trigger: modernization repeated `CQ-965` three consecutive iterations.

Findings:
- Use explicit Thought→Act cycles so each retry must change at least one action dimension (test case, invariant, fixture, or boundary) rather than re-running same patch shape.
- Add short reflective memory after each pass/fail attempt (what changed, what signal moved) to force next attempt diversification.
- Apply strict WIP discipline: cap same-task retries to 2 before forced task-slice split (new subtask id) to avoid local optimization loops.

Applied guidance for builder policy:
- Retry budget: max 2 on same task id.
- Third touch requires decomposition into narrower CQ child or a different validation axis.
- Log concrete delta evidence in notes (`new invariant`, `new fixture`, `new failure class`).

Sources:
- https://arxiv.org/abs/2210.03629
- https://arxiv.org/abs/2303.11366
- https://www.atlassian.com/agile/kanban/wip-limits
