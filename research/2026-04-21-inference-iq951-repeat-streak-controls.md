# Inference IQ-951 repeat streak controls (online synthesis)

Trigger: `inference` repeated `IQ-951` 3x in last 10 iterations.

Findings:
- Use capped exponential backoff + jitter for retries to avoid synchronized re-fail loops.
- Enforce retry budgets/circuit-breaker behavior: after N failed attempts on same task, block immediate reuse and force a different task class.
- Track flaky/failure-prone units explicitly and quarantine unstable paths from normal throughput until fixed.
- Prefer objective progress proofs before allowing same task recurrence (changed files + passing targeted validation).

Suggested loop guards:
- `same_task_max=2` in sliding window of 10.
- `cooldown_sec=1800` before same task ID can re-enter queue.
- `proof_required=true` (`files_changed > 0` and non-empty validation output).
- `fallback_pool`: inject 1 task from different subsystem when breaker opens.

References:
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://sre.google/sre-book/addressing-cascading-failures/
- https://docs.gitlab.com/development/testing_guide/test_results_tracking/
