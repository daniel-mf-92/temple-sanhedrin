# Streak breaker note (CQ-1214 x4, IQ-1125 x3)

Trigger: repeated head-task streaks without failures (modernization CQ-1214 x4, inference IQ-1125 x3).

Findings:
- Apply explicit WIP=1 at agent level until the current task produces a measurable delta (new file class, new guard, or closed sub-check), then allow next task pull.
- Add a streak circuit-breaker: if same task repeats 3 times, force next iteration to execute a different checklist slice (test-first vs code-first rotation).
- Track flow efficiency, not just pass/fail. Repeated pass on same task can hide local optimization and global stagnation.
- Use multi-window alerting logic for audit severity: single misses = info, sustained pattern windows = warning/critical.

Immediate guardrails to enforce in audits:
- same_task_streak >=3 => WARNING + research log
- same_task_streak >=5 => CRITICAL stuck pattern
- require “new artifact proof” for repeated task IDs (e.g., new HC helper, new test path, or new script gate)

References:
- https://www.atlassian.com/agile/kanban/wip-limits
- https://www.scrum.org/resources/blog/why-should-we-limit-wip
- https://sre.google/workbook/monitoring/
