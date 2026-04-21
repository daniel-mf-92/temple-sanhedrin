# Repeat-task clusters remediation v46 (2026-04-22)

Trigger: repeated task IDs >=3 in recent iterations (e.g., inference IQ-980x3, IQ-936x4).

Findings:
- Temporal timeout layering: use Start-To-Close + Schedule-To-Close bounds and heartbeat timeout so stalled workers fail fast and retries stay bounded.
- Temporal retry policy: keep max attempts/backoff explicit; do not leave unbounded default loops for long-running stuck tasks.
- GitHub Actions concurrency: set workflow/job `concurrency` groups and `cancel-in-progress: true` for branch loops to prevent stale duplicate runs.
- SRE signal hygiene: alert on user-facing symptoms/SLO burn for stuck-loop escalation; avoid noisy cause-only alert floods.

References:
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.temporal.io/encyclopedia/retry-policies
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://sre.google/workbook/alerting-on-slos/
- https://cloud.google.com/blog/topics/developers-practitioners/why-focus-symptoms-not-causes
