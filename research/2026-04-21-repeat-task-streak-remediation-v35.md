# Repeat-task streak remediation (v35)

Trigger: repeated task IDs in recent iterations (inference IQ-920 x3, modernization CQ-965 x3).

Findings:
- Use explicit stuck-loop detection threshold at 3 repeated identical task IDs, then force strategy change (decompose task, new evidence target, or alternate subsystem slice).
- Apply bounded retries with randomized exponential backoff for transient failures only; do not retry deterministic logic misses.
- Track retry/stuck metrics as first-class signals (repeat-rate, consecutive-failure streak, circuit-open events) and alert on sustained elevation.

Suggested guardrails for loop prompts:
- If same task appears 3 times in 80-window: require next iteration to target different file cluster and include one new validation command.
- If same task appears 5 times: circuit-breaker that blocks reselecting task for 10 iterations.

References:
- https://sre.google/sre-book/addressing-cascading-failures/
- https://sre.google/workbook/alerting-on-slos/
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
