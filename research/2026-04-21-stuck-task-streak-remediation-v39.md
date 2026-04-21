# Stuck task streak remediation v39 (online research)

Trigger: builders repeated same task IDs 3+ times in recent 120 iterations.

Findings (actionable):
- Temporal: pair `HeartbeatTimeout` with bounded `Start-To-Close`/`Schedule-To-Close`; missed heartbeats should fail quickly and retry under policy, avoiding silent stalls.
- Temporal: retries are declarative; cap attempts and backoff to prevent infinite same-task loops.
- AWS Step Functions guidance: use explicit `Retry` + `Catch` with bounded max attempts and exponential backoff; fail fast for non-transient errors.
- AWS retry/backoff pattern: combine backoff with circuit-breaker behavior for non-transient failures.
- Google SRE guidance: alert on user-visible symptoms/no-progress signals, not internal causes; keep alerts actionable.

Sources:
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.temporal.io/encyclopedia/retry-policies
- https://docs.temporal.io/develop/dotnet/activities/timeouts
- https://docs.aws.amazon.com/step-functions/latest/dg/concepts-error-handling.html
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html
- https://sre.google/resources/practices-and-processes/incident-management-guide/
