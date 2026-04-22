# Repeat task streak remediation v63

- Date: 2026-04-22
- Trigger: repeated same-task streaks observed in recent iterations (`CQ-1109` x4 contiguous; historical `IQ-990` x4)

## Findings (online)
- Use explicit activity timeout + heartbeat timeout so stalled attempts fail fast instead of silently consuming retries.
- Add bounded retry policy with backoff/jitter and cap attempts before escalation to avoid repeated no-progress loops.
- Use workflow/job concurrency control to cancel obsolete in-flight runs on superseded commits.
- Alert only on sustained/repeated failure patterns; treat isolated failures as informational noise.

## Source links
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://docs.cloud.google.com/memorystore/docs/redis/exponential-backoff
- https://sre.google/workbook/preface/
