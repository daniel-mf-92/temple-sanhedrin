# Repeat-task streak guardrails (v64)

Trigger: modernization task streaks (`CQ-1109`) and inference streaks (`IQ-1024`) repeating 3+ times in recent iterations.

Findings:
- Temporal recommends explicit activity timeout layering (Start-To-Close / Schedule-To-Close) plus heartbeat timeout to detect stalled work quickly.
- Temporal heartbeat + retry policy should be bounded to prevent silent long retry loops.
- Google SRE recommends multi-window burn-rate/symptom-based alerting to cut noisy single-failure reactions and focus on sustained reliability risk.
- GitHub Actions concurrency groups with `cancel-in-progress: true` prevent stale queued/running duplicates from amplifying repeat loops.

Suggested controls for builder loops:
- Keep single-failure events informational; alert only on sustained streak windows.
- Tag each iteration with progress fingerprint (task_id + touched-file hash + test hash) and escalate when unchanged across retries.
- Apply workflow/job concurrency keys on loop branches so superseded runs are canceled automatically.

References:
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.temporal.io/develop/java/activities/timeouts
- https://sre.google/workbook/alerting-on-slos/
- https://docs.github.com/en/actions/concepts/workflows-and-actions/concurrency
