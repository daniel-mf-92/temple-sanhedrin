# IQ-1137 repeat-streak remediation

Trigger: inference task `IQ-1137` repeated 3 consecutive iterations on 2026-04-22.

## Findings
- Add a hard re-run ceiling for the same task ID (max 2 consecutive retries); on hit, require scope expansion (new failing test, new file, or new invariant) before next attempt.
- Use failed-job-only reruns plus debug logging to separate flaky CI/tooling noise from actual code regressions before retrying the same task.
- Track retry budgets per run; if no new evidence appears after two retries, force a queue pivot to adjacent blocked work and return with fresh context.

## Sources
- https://docs.github.com/en/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs
- https://docs.github.com/en/actions/how-tos/monitor-workflows
- https://docs.github.com/en/actions/how-tos/monitor-workflows/enable-debug-logging
- https://arxiv.org/abs/2601.15195
