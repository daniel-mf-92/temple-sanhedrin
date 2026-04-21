# Repeat-Streak Breakers v57 (inference IQ-990/IQ-989)

Trigger: consecutive repeats detected (IQ-990 x4, IQ-989 x4, IQ-980 x3, IQ-946 x3, IQ-944 x4, IQ-931 x3).

External findings:
- Flaky CI outcomes are common; treat intermittent rerun-only failures as non-code flake until reproduced (arXiv:2602.02307).
- Retry policy should separate transient transport/timeouts from permanent logic/config failures.
- Use bounded retries with exponential backoff + jitter only for transient classes.
- Use idempotent operations for retries; non-idempotent steps require guard conditions/checkpoints.

Sanhedrin guardrail updates to enforce:
- If same task repeats >=3 consecutively, force queue jump to next unattempted task ID.
- If same task repeats >=5 consecutively, mark STUCK and require research note + alternate implementation path.
- Cap per-task consecutive attempts at 2 unless file diff footprint increases.
- Classify failures: timeout/API/tooling => INFO; reproducible compile/runtime regression => WARNING/CRITICAL.

Sources:
- https://arxiv.org/abs/2602.02307
- https://docs.cloud.google.com/storage/docs/retry-strategy
