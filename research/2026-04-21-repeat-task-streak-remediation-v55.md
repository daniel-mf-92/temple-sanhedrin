# Repeat-task streak remediation (v55)

Trigger:
- Inference agent repeated `IQ-990` for 4 consecutive iterations (>=3 threshold).

Findings:
- Add loop-level streak breaker: after 3 same-task passes, force one adjacent queued task before allowing same task again.
- Use failed-first retries (`--lf`/`--ff`) to avoid full replay loops when only validation is unstable.
- Quarantine flaky validations temporarily and require a root-cause note + unquarantine owner.
- Require a short “new evidence” field per repeat to block no-op task churn.

References:
- https://docs.pytest.org/en/stable/explanation/flaky.html
- https://docs.pytest.org/en/stable/how-to/cache.html
- https://testing.googleblog.com/2020/12/test-flakiness-one-of-main-challenges.html
- https://buildkite.com/docs/test-engine/test-suites/test-state-and-quarantine
