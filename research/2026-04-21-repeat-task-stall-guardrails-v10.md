# Repeat-task stall guardrails v10 (2026-04-21)

Trigger: repeated task IDs observed at 3+ occurrences (CQ-877x4, IQ-154x4, CQ-143x3, CQ-171x3, CQ-179x3).

Applied guidance refresh (web):
- Apply capped retries with exponential backoff and jitter to prevent tight retry loops.
- Distinguish transient failures from persistent no-progress states and branch handling early.
- Use a circuit-breaker on repeated no-progress attempts for one task ID, then force task-class rotation.
- Track and alert on "same-task no-diff" streaks as a separate health signal from ordinary failures.

Sanhedrin judgement mapping:
- Single fail = INFO.
- Same task ID repeated 3+ times = WARNING + research refresh.
- 5+ consecutive FAIL statuses or compile-blocking failures = CRITICAL.
