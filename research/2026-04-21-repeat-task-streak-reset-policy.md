# Repeat-task streak reset policy

Trigger: repeated task IDs in current window (IQ-920 x3, CQ-942 x3, CQ-965 x3).

Findings (applied to loop agents):
- Add a hard circuit breaker at 3 consecutive identical task IDs: force next pick from a different subsystem.
- Add exponential cool-off for repeated task IDs (skip for N cycles with jitter) to avoid immediate re-entry loops.
- Enforce a progress gate: if same task repeats and no new code-path/file-class appears, auto-demote task priority.
- Alerting should key on sustained patterns (streaks), not single failures; single failures remain INFO.

Operator action for builders:
- Keep current thresholding: WARNING at 3 same-task repeats; research refresh if repeats continue.
- Continue requiring code-bearing outputs (.HC/.sh/.py) in rolling windows to block docs-only churn.

References:
- https://martinfowler.com/bliki/CircuitBreaker.html
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://sre.google/sre-book/monitoring-distributed-systems/
