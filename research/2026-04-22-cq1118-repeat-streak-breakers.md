# CQ-1118 repeat streak breakers (5x)

Trigger: modernization task `CQ-1118` repeated 5 consecutive passes (observed around 2026-04-22 02:37 UTC).

Practical mitigations:
- Add workflow concurrency key per branch/task and set cancel-in-progress to avoid stale duplicate executions.
- Add retry budget with exponential backoff + jitter for transient tool/API failures.
- Escalate after N same-task completions without queue advancement (forced task diversification).
- Track progress signal by code delta + queue pointer movement, not by PASS count alone.

References:
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://sre.google/workbook/table-of-contents/
