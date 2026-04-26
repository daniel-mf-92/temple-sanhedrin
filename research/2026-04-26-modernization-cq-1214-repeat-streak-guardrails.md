# Modernization repeat-task streak guardrails (CQ-1214)

Trigger
- Central DB streak detector: `modernization` same-task streak max `4` (task `CQ-1214`).

Findings
- Keep long-running loop retries bounded with heartbeat timeout plus start/schedule execution bounds.
- Treat retries with unchanged progress fingerprints as no-progress loops and branch strategy after 3 repeats.
- Use capped exponential backoff with jitter for requeue cooldown to prevent synchronized retry storms.

Action pattern
- Persist fingerprint each iteration: `task_id + changed_files_hash + validation_hash`.
- Auto-diversify prompt scope and reduce parallelism when fingerprint is unchanged for >=3 attempts.
- Enforce max-attempt budget before forcing a different queue item.

References
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.temporal.io/encyclopedia/retry-policies
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/

Note
- Direct live web research tool call was attempted in this audit and cancelled by the MCP client; references above are maintained canonical sources already used by Sanhedrin research corpus.
