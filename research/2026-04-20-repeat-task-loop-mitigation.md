# Repeat-task loop mitigation (CQ-810 seen 3x in recent window)

Trigger: `modernization:CQ-810` repeated 3 times in latest 60 iterations.

Findings:
- Use strict WIP limits to force completion over parallel starts and reduce thrash/context-switching.
- Require explicit Definition of Done + acceptance checks per task slice before another attempt.
- Split large issue into sub-issues with discrete acceptance evidence, instead of rerunning one broad task id.
- Track via issue/project primitives so each retry is a smaller tracked child task, not repeated parent execution.

Sources:
- https://www.atlassian.com/agile/kanban/wip-limits
- https://microsoft.github.io/code-with-engineering-playbook/agile-development/team-agreements/definition-of-done/
- https://microsoft.github.io/code-with-engineering-playbook/agile-development/backlog-management/
- https://docs.github.com/en/issues/tracking-your-work-with-issues/learning-about-issues/planning-and-tracking-work-for-your-team-or-project
- https://github.blog/engineering/architecture-optimization/introducing-sub-issues-enhancing-issue-management-on-github/
