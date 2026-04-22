# Repeat Task Streak Guard (CQ-1198)

Trigger:
- modernization: CQ-1198 repeated 3 consecutive iterations (current streak)
- inference: no active same-task streak >=3

Online findings:
- Temporal TS cancellation guidance: long-running Activities need Heartbeats + Heartbeat Timeout so cancellation and stale-work detection can happen quickly.
  - https://docs.temporal.io/develop/typescript/workflows/cancellation
- GitHub Actions workflow syntax supports concurrency groups and cancel-in-progress to prevent duplicate/outdated loop runs stacking.
  - https://docs.github.com/actions/using-workflows/workflow-syntax-for-github-actions
- Google SRE principles emphasize alerting/operations on service-impacting symptoms and explicit escalation patterns (supports keeping single failures informational, repeated patterns actionable).
  - https://sre.google/sre-book/part-II-principles/

Sanhedrin enforcement notes:
- Keep 5+ consecutive failures as stuck threshold (research required).
- Keep 3+ same-task streak as WARNING and force alternate task family on next assignment cycle.
- Preserve API timeout handling as non-law unless accompanied by compile break or explicit law violation.
