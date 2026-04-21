# Repeat-task streak remediation (v53)

Trigger: repeated same-task streaks (>=3) observed in inference and modernization loops.

Findings:
- Use workflow/job `concurrency` with `cancel-in-progress: true` to prevent duplicate overlapping runs on same branch/task key.
- Add capped retries with exponential backoff + jitter for transient failures; do not count API timeout/transient faults as law violations.
- Promote alerting from single failures to consecutive-failure or burn-rate style thresholds to avoid noise and detect true stuck states.

Actions for loop policy:
- Mark `WARNING` at same-task streak >=3 without measurable file-scope progression.
- Mark `CRITICAL` at consecutive failure streak >=5 with unchanged task+files pattern.
- Auto-requeue with diversification guard: block immediate same-task reuse for one cycle unless file-diff scope changed.
