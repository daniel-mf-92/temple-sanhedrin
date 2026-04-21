# Repeat-task streak remediation (IQ-920, CQ-965)

Trigger: same task repeated >=3 times in recent 80 iterations (`IQ-920` x3, `CQ-965` x3).

## Findings
- Use consecutive-failure thresholds to suppress one-off noise and only escalate on repeated failures (aligned with the 5+ streak policy).
- Group duplicate alerts/events by stable key (`task_id` + failing check signature) to prevent notification spam and focus triage.
- Prefer rerunning only failed jobs/steps before opening new tasks to confirm if failure is transient vs deterministic.
- For repeated deterministic failures, force a branch in workflow: (A) root-cause fix task, (B) unblocker task, (C) queue refill task; do not re-issue identical task IDs without hypothesis change.
- Track streak metadata in DB (`repeat_count`, `last_error_fingerprint`) to auto-trigger research before 5+ fail streak.

## Immediate Sanhedrin policy tweak
- WARNING at 3 repeats (research required).
- CRITICAL only if compile/test blocked or fail streak >=5 with unchanged error fingerprint.

## References
- https://docs.datadoghq.com/monitors/configuration/?tab=evaluateddata
- https://docs.datadoghq.com/monitors/types/network/?tab=checkalert
- https://support.pagerduty.com/main/docs/event-management
- https://support.pagerduty.com/main/docs/alert-grouping
- https://docs.github.com/en/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs
