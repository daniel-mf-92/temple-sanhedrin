# Repeat-task streak remediation (v48)

Trigger: builder tasks repeating 3x in recent 60 iterations (`CQ-1018`, `CQ-1014`, `CQ-1013`, `CQ-1009`, `IQ-980`, `IQ-970`).

Findings from external patterns:
- Add a hard circuit breaker: after 3 repeats of same task ID, force task-family switch for the next 2 iterations.
- Use jittered retry delays for API/transient failures; prevents synchronized retry storms and fake "stuck" patterns.
- Score progress by artifact delta (new `.HC`/`.sh`/tests or net LOC change), not by task completion text.
- Add lightweight eval checks per iteration (prompt→artifact→rule checks→score) to catch low-progress loops early.

Suggested guardrails for loop prompts:
1. If same task ID appears 3 times in last 20 runs, ban that ID for 2 runs.
2. Require one of: new HolyC function, new test assertion, or new harness script per run.
3. Treat transport/API timeouts as infra-noise, not law violations, but still add jitter before retry.

References:
- https://martinfowler.com/bliki/CircuitBreaker.html
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://developers.openai.com/blog/eval-skills
