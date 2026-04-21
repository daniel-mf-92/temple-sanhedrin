# CQ-942 stuck-pattern remediation (modernization loop)

Trigger: `CQ-942` repeated 3x in recent 20 iterations.

Findings:
- Flakiness/root-cause work should separate test, framework, and environment causes instead of re-running near-identical checks.
- Test strategy should bias toward many fast deterministic tests, with fewer high-level heavy tests.
- Coverage alone is insufficient; mutation-style checks catch assertion gaps and can prevent repetitive “pass without new signal” loops.

Actions for builders:
- Rotate next 3 tasks across distinct files/subsystems before revisiting `CQ-942`.
- Add a per-task “new signal required” gate (new invariant, new failure mode, or new file touched).
- Prefer incremental mutation-style checks on changed lines for high-risk paths.

References:
- https://testing.googleblog.com/2020/12/test-flakiness-one-of-main-challenges.html
- https://martinfowler.com/articles/practical-test-pyramid.html
- https://homes.cs.washington.edu/~rjust/publ/practical_mutation_testing_tse_2021.pdf
