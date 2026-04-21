# Repeat-task stall guardrails v7 (2026-04-21)

Trigger: repeated task IDs in recent builder iterations (`IQ-842` x3, `IQ-844` x3).

Findings (web):
- GitHub Actions supports scoped re-run at workflow/job level; use re-run only after root-cause label is set to avoid blind retry loops.
- Google testing guidance: flaky failures should be isolated and tracked separately so true regressions are not buried by retry noise.
- SRE-oriented alerting guidance: treat consecutive failure streaks as paging signals; single failures stay informational.

Sanhedrin policy update:
- If same task appears >=3 times in last 30 iterations, require one new code-path delta check before another retry.
- If failure streak reaches >=5, auto-create RESEARCH entry + enforce task rotation to a neighbor item for one cycle.
- Distinguish infra/API timeout from code regression; do not count timeout-only failures toward law violation.

References:
- https://docs.github.com/en/rest/actions/workflow-runs
- https://testing.googleblog.com/2016/05/flaky-tests-at-google-and-how-we.html
- https://sre.google/workbook/alerting-on-slos/
