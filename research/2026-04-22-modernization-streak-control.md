# Streak Control for Repeated CQ Task IDs (CQ-1191 x3)

Trigger: modernization agent repeated `CQ-1191` three consecutive iterations.

Findings:
- Add bounded retries with exponential backoff + jitter to avoid hot-loop repetition under transient failures.
- Add a circuit-breaker guard for the same task-id/file-set combo after N repeats; force queue rotation or human review.
- Use GitHub Actions workflow/job `concurrency` with `cancel-in-progress: true` on loop branches so stale runs are canceled.

Applied-to-loop guidance:
- If same task appears 3 times and output diff entropy is low, auto-mark as `WARNING` and rotate to next CQ.
- Keep max consecutive identical task-id budget <=2 unless changed files differ materially.

References:
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://docs.aws.amazon.com/sdkref/latest/guide/feature-retry-behavior.html
- https://martinfowler.com/bliki/CircuitBreaker.html
- https://docs.github.com/en/actions/concepts/workflows-and-actions/concurrency
- https://docs.github.com/en/enterprise-cloud@latest/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
