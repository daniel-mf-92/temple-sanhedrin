# CQ-1223 repeat-streak mitigation

Trigger: modernization showed task repeat pattern (CQ-1223 repeated >=3x in recent window).

Findings (online):
- Add trace-level scoring to detect “no-net-progress” runs and force a task switch after threshold.
- Separate transient tool failures from policy/code failures; only repeated non-transient failures should trigger remediation.
- Use a hard cap on same-task retries (e.g., 2) then enqueue a neighboring task category for diversification.

Sanhedrin guardrail:
- Keep 5+ consecutive failures as STUCK threshold, but also flag same-task streak >=3 as WARNING with forced diversification recommendation.

Sources:
- https://developers.openai.com/api/docs/guides/trace-grading
