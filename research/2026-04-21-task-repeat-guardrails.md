# Task Repeat Guardrails (CQ-942)

- Trigger: modernization task `CQ-942` repeated 3x in recent window.
- Pattern: repeated PASS rewrites on same smoke harness indicate refinement churn, not hard failure.

## Findings
- Add a "two-pass cap" rule: after 2 PASSes on same task, require either merge-up or explicit new acceptance criterion.
- Add diff novelty gate: block same-task continuation when net new assertions/checks are below threshold.
- Add queue nudge: auto-promote next CQ after consecutive PASSes on same CQ unless last run was FAIL/BLOCKED.
- Add closure rubric: require explicit "what remains" line in notes before re-queueing same task.

## Sources
- https://thenewstack.io/github-agentic-workflows-overview/
- https://www.prebug.com/blog/from-backlog-chaos-to-clarity-how-ai-is-reshaping-modern-bug-reporting-and-qa-workflows-2025-guide
