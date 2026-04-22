# CQ-1098 repeat streak breakers

Trigger: modernization task `CQ-1098` appeared 3 times in recent iterations (repeat-streak warning).

Findings to apply in loop governance:
- Add a task-level circuit breaker: if same task repeats 3x without materially new files/tests, auto-demote task priority and force next pick from different subsystem.
- Use bounded retry with exponential backoff + jitter for transient tool failures; do not keep same task at head of queue indefinitely.
- Use SLO-style alert thresholds for loop health (e.g., repeat streak length, no-new-code iterations) so stuckness is detected before 5+ failure/doc-only streaks.

References:
- https://martinfowler.com/bliki/CircuitBreaker.html
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html
- https://sre.google/workbook/alerting-on-slos/
