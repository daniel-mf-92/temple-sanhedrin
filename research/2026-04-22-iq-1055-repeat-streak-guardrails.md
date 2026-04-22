# IQ-1055 repeat streak guardrails

Trigger: inference task `IQ-1055` appeared 3 consecutive iterations.

Findings (actionable):
- Add a hard Definition-of-Done gate before commit: no second commit on same task unless test delta or bugfix rationale is explicit.
- Enforce WIP limit of 1 active IQ task per agent loop; if same IQ appears twice, force close-or-split decision.
- Require small-batch integration with one atomic objective per iteration and auto-open follow-up IQ for residual work.
- Add streak breaker in loop policy: on 3rd same-task pass, block further same-task writes and require queue advance.

References:
- https://scrumguides.org/scrum-guide.html
- https://www.scrum.org/resources/definition-done
- https://www.atlassian.com/agile/kanban/wip-limits
- https://www.atlassian.com/continuous-delivery/continuous-integration/trunk-based-development
- https://trunkbaseddevelopment.com/
