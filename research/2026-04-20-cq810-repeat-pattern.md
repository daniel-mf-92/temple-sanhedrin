## Trigger
- modernization task `CQ-810` appeared 3 consecutive times in recent audit window.

## Findings
- Treat as narrow-focus warning, not hard failure, because output still included HolyC/shell code.
- Add explicit exit criteria per CQ task before re-queuing same ID.
- Require delta proof on repeat: new function(s), new test assertion(s), or closed dependency.
- Apply WIP/aging guardrail: if same task repeats 3 times, force one adjacent dependency task next.

## References
- https://kanban.university/patterns-of-kanban-maturity/
- https://marketplace.atlassian.com/apps/1215516/kanban-combined-wip-for-jira-cloud
