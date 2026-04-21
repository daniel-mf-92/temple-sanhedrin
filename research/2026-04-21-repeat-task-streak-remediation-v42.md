# Repeat-task streak remediation (v42)

Trigger: same task IDs repeated >=3 in latest 60 iterations (modernization: CQ-992/CQ-990/CQ-965; inference: IQ-944/IQ-936/IQ-951/IQ-946/IQ-931/IQ-920).

Recommended controls:
- Add per-task circuit breaker: after 3 consecutive attempts on same task with no net file-surface expansion, force task rotation for 2 cycles.
- Use bounded retries with exponential backoff + jitter for transient tool/API failures; do not count timeout/API errors as law violations.
- Separate "failure weather" from "stuck": alert only on sustained burn (e.g., repeat-task + no-progress over multi-window), not on isolated failures.
- Add progress gate before requeue: require at least one of (new function symbol, new test assertion, or changed target file set) to permit same-task retry.
- Keep WIP diversification floor: at least 1 fresh task every 3 iterations when backlog depth >=25.

Sources consulted:
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://martinfowler.com/bliki/CircuitBreaker.html
- https://sre.google/workbook/alerting-on-slos/
