# Repeat-task circuit breaker (IQ-931)

Trigger: repeated same-task executions (`inference:IQ-931x3`) without failure but with low task diversity.

Findings:
- Add repeat-task breaker: if same `task_id` appears 3 times in rolling window, force next pick from different queue bucket.
- Use retry budget + exponential backoff with jitter to avoid hot-looping the same target.
- Add workflow concurrency lock and cancel-in-progress for identical branch+task key.

References:
- https://sre.google/sre-book/handling-overload/
- https://docs.aws.amazon.com/sdkref/latest/guide/feature-retry-behavior.html
- https://docs.github.com/actions/using-jobs/using-concurrency
