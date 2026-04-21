# Inference repeat streak mitigation (IQ-839 x3)

Trigger: inference repeated `IQ-839` 3 consecutive iterations.

Findings:
- Use workflow/job `concurrency` with `cancel-in-progress: true` to prevent stale duplicate runs from occupying queue slots.
- Keep retries bounded and jittered; unbounded retry loops convert transient failures into sustained contention.
- Classify retryable vs non-retryable errors; deterministic errors should fail fast and force task rotation.
- Alert on stuck symptom (same task >=3 with no meaningful delta), not low-level causes, and require an actionable remediation step.
- Add local guardrail: if same task repeats >=3 without new `.HC` logic or new passing validation artifact, rotate to next queued IQ for one cycle.

Temple-specific policy:
- Keep single failures as INFO; treat repeated no-progress same-task loops as WARNING.
- Escalate to CRITICAL only if compile/CI blocking failure appears or fail streak reaches >=5.

References:
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://docs.github.com/en/actions/concepts/workflows-and-actions/concurrency
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://sre.google/resources/practices-and-processes/incident-management-guide/
