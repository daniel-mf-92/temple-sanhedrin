# Repeat-task streak remediation v74

Trigger: modernization CQ-1152 repeated 4x; inference IQ-1062 and IQ-1063 repeated 3x in recent window.

Findings:
- Add explicit per-attempt timeout bounds (start-to-close + schedule-to-close) and capped retries so stuck attempts fail fast instead of silent looping.
- Emit heartbeat progress payload with task/stage/artifact-hash and treat unchanged payload across >=3 attempts as no-progress.
- Apply circuit-breaker behavior for repeated identical task IDs: open breaker, force alternate task class, then half-open retry.
- Alert on no-progress streak and repeat-task streak, not on single transient failures/timeouts.

References:
- https://docs.temporal.io/develop/typescript/failure-detection
- https://docs.temporal.io/encyclopedia/retry-policies
- https://martinfowler.com/bliki/CircuitBreaker.html
