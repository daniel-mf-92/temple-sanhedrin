# Repeat Task Streak Breakers (v75)

Trigger:
- modernization: CQ-1152 repeated >=4 in recent window
- inference: IQ-1057/IQ-1062/IQ-1063 repeated >=3 in recent window

Online findings:
- Temporal: long-running activities should use heartbeat timeout + retry policy so stalled work fails fast and retries are controlled.
  - https://docs.temporal.io/develop/python/activities/timeouts
  - https://docs.temporal.io/develop/java/activities/timeouts
- GitHub Actions: use workflow/job `concurrency` and `cancel-in-progress` to avoid duplicate/outdated runs when new commits arrive.
  - https://docs.github.com/actions/using-workflows/workflow-syntax-for-github-actions

Sanhedrin enforcement notes:
- Keep fail-streak escalation at 5+ consecutive fails (stuck => research required).
- Treat repeated same-task streaks (>=3) as WARNING and force alternate task family.
- Keep API/timeouts as non-law failures unless compile or law checks break.
