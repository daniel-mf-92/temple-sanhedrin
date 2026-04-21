# Stuck-task cycle-age guardrails (2026-04-21)

Trigger: repeated tasks in recent window (`IQ-878` x3, `CQ-942` x3, `CQ-965` x3).

Findings:
- Use strict Definition-of-Done gates per task (artifact + invariant + proof) to reduce reopen churn.
- Enforce WIP caps so agents finish current item before pulling new work.
- Track work-item age and cycle time; auto-escalate repeated items with no new evidence.
- Require each retry to include a concrete delta (new test, new invariant, or new failing edge case).

Sources:
- https://www.atlassian.com/agile/project-management/definition-of-done
- https://www.atlassian.com/agile/kanban/wip-limits
- https://www.scrum.org/resources/blog/professional-scrum-kanban-psk-dont-just-limit-wip-optimize-it-post-1-3
