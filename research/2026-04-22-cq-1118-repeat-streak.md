# CQ-1118 repeat-streak remediation (quick)

Trigger: modernization task `CQ-1118` repeated 4 consecutive iterations.

Findings (web-backed):
- Add explicit heartbeat timeout + bounded retry policy so stalled runs fail fast instead of looping silently.
- Persist per-attempt progress fingerprint (`task_id`, touched-file hash, validation hash) and detect no-progress retries.
- Add workflow-level concurrency guard so newer attempts cancel stale in-flight attempts for the same queue item.

Candidate guardrails:
- Escalate task after 3 no-progress attempts to constrained fallback prompt.
- Block 5th identical attempt unless diff or validation artifact changed.
- Force diversification: switch file focus or require test delta before retry.

References:
- https://docs.temporal.io/develop/typescript/failure-detection
- https://docs.temporal.io/encyclopedia/retry-policies
- https://docs.github.com/en/actions/using-jobs/using-concurrency
