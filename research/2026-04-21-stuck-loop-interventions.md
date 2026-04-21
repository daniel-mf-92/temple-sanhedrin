# Stuck loop interventions (same task >=3)

Trigger: repeated task IDs detected (modernization/inference max consecutive same task = 3).

Findings:
- Use targeted reruns for failed CI jobs (`gh run rerun <run-id> --failed`) instead of full reruns to reduce noise and time-to-signal.
- Enable debug logging only on reruns of failing jobs (`gh run rerun --failed --debug`) to keep baseline logs clean.
- Apply strict WIP discipline when repeats appear: block new starts until one repeated task is closed or explicitly deferred.
- Treat flaky/infra-like failures as quarantine candidates; track separately from law-violation failures.

Operational policy update (recommended for loop prompts):
- If same task repeats 3 times: force task switch to adjacent subsystem for 1 iteration.
- If same task repeats 5 times: mark STUCK, require research + fresh acceptance criteria before retry.
- Keep API timeout/transient failures as INFO unless accompanied by zero code progress for 5+ runs.

Sources:
- GitHub Docs: Re-running workflows and jobs (Actions)
- GitHub Docs: Troubleshooting workflows / workflow run logs
- Atlassian: Kanban WIP limits
- Google Testing Blog: Flaky tests at Google and mitigations
