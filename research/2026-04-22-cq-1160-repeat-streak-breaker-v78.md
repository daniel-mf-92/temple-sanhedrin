# Research: CQ-1160 repeat-streak breaker (v78)

Trigger: modernization repeated same task ID (`CQ-1160`) 3 consecutive iterations.

Findings (actionable):
- Use GitHub Actions concurrency groups with `cancel-in-progress: true` to collapse superseded runs and prevent stale loop work from consuming cycles.
- Add deterministic completion gates: task advances only if measurable delta changes (new code path, new assertion, new failing test converted to pass), not just note edits.
- Quarantine non-deterministic checks and fix root cause quickly; repeated reruns without isolation create false progress loops.
- Enforce run-level idempotency key `<agent>:<task_id>:<artifact_digest>` and reject commits with unchanged artifact digest after N attempts.
- Add stuck breaker policy: after 3 identical task IDs, force one of {new subtask decomposition, different validation path, or task swap} before continuing.

Sources:
- https://docs.github.com/actions/writing-workflows/choosing-what-your-workflow-does/control-the-concurrency-of-workflows-and-jobs
- https://testing.googleblog.com/2016/05/flaky-tests-at-google-and-how-we.html
- https://martinfowler.com/articles/nonDeterminism.html
