# Repeated Task Streak Loop-Breaking (2026-04-21)

Trigger: repeated task IDs in recent 80 builder iterations (`IQ-920 x3`, `CQ-942 x3`, `CQ-965 x3`).

Findings (actionable):
- Add task cooldown: after 2 consecutive attempts on same task ID, force next pick to a different queue item.
- Add retry budget: cap same-task retries per 24h and route overflow to research/refactor queue.
- Add progress gate: require measurable delta (new code file diff or test delta) before allowing same task ID again.
- Add stale-task detector: if same task appears 3x with low artifact diversity, auto-tag as stuck.
- Add exploration step: on stuck tag, require one external reference + one alternative implementation sketch.

Suggested thresholds:
- Soft warning: 3 repeats in rolling 80.
- Hard stuck: 5 repeats in rolling 80 or 5 consecutive non-pass outcomes.

Sources:
- NSA/CISA guidance on defending CI/CD environments (focus on resilient pipeline controls and guardrails).
- Retry-policy reliability guidance from CI/CD best-practice literature (avoid unbounded retries, use bounded backoff).
