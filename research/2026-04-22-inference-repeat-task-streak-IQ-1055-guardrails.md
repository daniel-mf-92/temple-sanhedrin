# Inference repeat-task streak guardrails (IQ-1055)

- Trigger: inference agent repeated `IQ-1055` for 3 consecutive iterations.
- Temporal guidance: pair `Start-To-Close`/`Schedule-To-Close` with `HeartbeatTimeout` to fail stalled activities quickly instead of silent long retries.
- Temporal guidance: heartbeats can carry retry-resume details; persist task/stage hashes to detect no-progress retries.
- Temporal guidance: bound retries with explicit retry policy limits/backoff to avoid unbounded loops.
- GitHub guidance: use workflow events/filters to add automated streak detectors that open warnings when same task repeats N times without artifact delta.
- GitHub engineering guidance: treat multi-agent systems like distributed systems with explicit state handoffs and invariant checks.

## Links
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.temporal.io/encyclopedia/retry-policies
- https://docs.temporal.io/develop/dotnet/activities/timeouts
- https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows
- https://github.blog/ai-and-ml/generative-ai/multi-agent-workflows-often-fail-heres-how-to-engineer-ones-that-dont/
