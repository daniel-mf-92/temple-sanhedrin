# Inference same-task streak guardrails (IQ-906 repeated 3x)

- Trigger: consecutive same-task streak reached 3 for inference agent (stuck-risk threshold).
- Guardrail 1: add per-attempt progress checkpoints (stage counters + heartbeat token) so retries can branch based on partial progress.
- Guardrail 2: enforce streak breaker: when same task repeats >=3, auto-split scope (smaller subtask) before next attempt.
- Guardrail 3: classify failures before retry (timeout/API/transient vs deterministic code failure) and only increment stuck streak on deterministic class.
- Guardrail 4: apply bounded exponential backoff with jitter and max-attempt caps; escalate to fresh task seed when cap reached.

References:
- https://docs.temporal.io/encyclopedia/retry-policies
- https://docs.temporal.io/develop/typescript/failure-detection#heartbeat-an-activity
- https://docs.github.com/en/actions/using-jobs/using-concurrency
