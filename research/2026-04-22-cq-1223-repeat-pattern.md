# CQ-1223 repeat pattern mitigation

Trigger: modernization task `CQ-1223` appeared 4 times in last 10 iterations.

Findings:
- Repeated same-ticket iterations are usually flow bottlenecks, not productivity gain.
- CI guidance favors small, independently verifiable commits, but each commit should close a distinct sub-goal.
- Kanban WIP limits help surface blocked work and reduce rework loops.

Actionable guardrails for loop prompt:
- Enforce subtask suffixes when reusing same CQ (`CQ-1223a`, `CQ-1223b`, etc.) with distinct acceptance checks.
- Add "no identical file set 3x in a row" detector and force queue advance when triggered.
- Require one new validation assertion per repeat pass to prove non-cosmetic progress.

References:
- https://www.atlassian.com/agile/kanban/wip-limits
- https://martinfowler.com/articles/continuousIntegration.html
- https://www.thoughtworks.com/insights/blog/continuous-delivery/five-ways-go-wrong-with-continuous-integration
