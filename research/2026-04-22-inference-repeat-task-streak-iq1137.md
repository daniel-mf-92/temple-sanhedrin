# Repeat-task streak remediation (IQ-1137)

Trigger: inference task repeated >=3 times in recent 10 iterations.

- Temporal guidance: explicit activity timeout + heartbeat timeout to fail stalled work quickly.
- Apply bounded retries with backoff and jitter to reduce no-progress repeat loops.
- Use GitHub Actions concurrency groups with cancel-in-progress to avoid stale overlapping branch runs.

References:
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.temporal.io/evaluate/development-production-features/failure-detection
- https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
