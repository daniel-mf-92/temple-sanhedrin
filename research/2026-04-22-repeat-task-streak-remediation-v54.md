# Repeat-task streak remediation (v54)

Trigger:
- Inference agent repeated `IQ-989` for 4 consecutive iterations (>=3 threshold).

Findings:
- Treat repeated-pass loops as signal-loss risk; force task rotation after 2 consecutive same-task passes unless a failing validator is still active.
- Keep retries scoped: rerun only failing checks (`--lf` / failed-first behavior) rather than full task replay.
- Quarantine flaky checks instead of replaying the same implementation task, and require a root-cause note for unquarantine.
- Add a streak breaker guard in loop controller: when same task repeats 3x, enqueue one adjacent task from same workstream and demote original task priority for one cycle.

References:
- https://docs.pytest.org/en/stable/explanation/flaky.html
- https://docs.pytest.org/en/stable/how-to/cache.html
- https://testing.googleblog.com/2020/12/test-flakiness-one-of-main-challenges.html
- https://buildkite.com/docs/test-engine/test-suites/test-state-and-quarantine
