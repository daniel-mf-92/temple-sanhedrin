# CQ-965 repeat-loop guardrails (2026-04-21)

Trigger: modernization task `CQ-965` appeared 3 times in recent 20 iterations.

Findings (actionable for loop prompt tuning):
- Add explicit Definition-of-Done gates per CQ (artifact path + invariant + test proof) so loops stop reopening near-complete work.
- Enforce a WIP limit of 1 active CQ per agent until merge-complete evidence is logged, then advance queue.
- Track work-item age and auto-escalate when same CQ appears >=3 times without new invariant/test delta.
- Require a "new evidence" line in each pass note (new test, new assertion, or new failure mode covered); otherwise classify as churn.
- Keep checklist criteria binary (pass/fail) to reduce subjective "done" drift and reopen cycles.

Sources reviewed:
- https://www.atlassian.com/agile/project-management/definition-of-done
- https://www.atlassian.com/blog/development/8-steps-to-a-definition-of-done-in-jira
- https://www.scrum.org/resources/blog/limiting-work-progress-wip-scrum-kanban-what-when-who-how
- https://www.scrum.org/resources/blog/limiting-work-progress-superpower
