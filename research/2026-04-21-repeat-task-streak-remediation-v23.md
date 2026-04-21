# Repeat-task streak remediation (v23)

Date: 2026-04-21
Trigger: modernization CQ-914 x6; inference IQ-878 x5 (recent120)

## Evidence-backed controls
- Classify failures: transient (timeouts/API flake) vs deterministic (logic/spec mismatch). Only deterministic failures should consume task-streak budget.
- Use bounded retries with exponential backoff + jitter; avoid synchronized immediate retries after loop ticks.
- Add max-attempt cap per task lease (e.g., 3) and force task rotation after cap.
- Persist per-task `last_error_fingerprint` and `attempt_count`; if fingerprint repeats 3x consecutively, auto-escalate to research + alternate-task fallback.
- Add active deadline/TTL for in-flight work unit; expire stale leases and requeue with reduced scope.
- Require progress signal between retries (changed code file set or test delta), otherwise mark as non-progress retry.

## Concrete loop patch targets
- `TempleOS/automation/codex-modernization-loop.sh`
  - Implement `TASK_STREAK_MAX=3`, `ERROR_FINGERPRINT_WINDOW=3`, `RETRY_JITTER_SEC=5..30`.
- `holyc-inference/automation/codex-inference-loop.sh`
  - Same controls plus `ALT_TASK_ON_STREAK=1` to avoid IQ pinning.
- `temple-sanhedrin/automation/codex-sanhedrin-loop.sh`
  - Detect builder streaks from central DB and emit WARNING at 3+, CRITICAL at 5+ consecutive same-task fails/no-progress.

## Source notes
- Google Cloud retry strategy: truncated exponential backoff with jitter and idempotency checks.
- Temporal retry policy docs: default activity retries are automatic; cap attempts and tune backoff explicitly.
- Kubernetes Job docs: `backoffLimit` and `activeDeadlineSeconds` terminate runaway retry loops.

References:
- https://docs.cloud.google.com/iam/docs/retry-strategy
- https://docs.temporal.io/encyclopedia/retry-policies
- https://kubernetes.io/docs/concepts/workloads/controllers/job/
