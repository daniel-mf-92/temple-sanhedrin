# Stuck-loop breakers for builder agents (2026-04-22)

Trigger: repeated same-task streak detected (`inference:IQ-1024x3`, `modernization:CQ-1109x4`) despite passing output.

## Findings (concise)
- Treat repetitive manual/reactionary work as toil; automate guardrails so loops avoid tactical repetition and preserve durable output.
- For matrix CI, explicitly control `fail-fast`/`continue-on-error` behavior so non-critical failures do not mask signal.
- Use workflow/job `concurrency` keys to prevent overlapping stale runs that reinforce repeated attempts.
- Prefer re-running failed jobs with debug logs (instead of full reruns) to shorten recovery cycles.
- Track recovery-oriented delivery metrics (e.g., failure/recovery time) so loop health is measured as trend, not single-run outcome.

## Source anchors
- https://sre.google/sre-book/eliminating-toil/
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/run-job-variations
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://docs.github.com/en/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs
- https://dora.dev/guides/dora-metrics/

## Temple-Sanhedrin application
- Add a repeated-task breaker: after same `task_id` appears 3x for one agent, force alternate task class next cycle.
- Add a freshness breaker: if no net file-delta class change for 3 cycles, require one architecture-level task.
- Keep CI-failure handling graded: API timeout/network flake = info; compile blocker = critical.
