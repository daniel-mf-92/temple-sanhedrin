# Modernization same-task streak remediation (CQ-1351/CQ-1352)

Trigger: Sanhedrin detected modernization `task_id` repeated 3 consecutive iterations.

Findings (external references):
- Temporal recommends explicit timeout layering (`Start-To-Close`, `Schedule-To-Close`, and heartbeat timeout) so stalled activity attempts fail fast instead of silently looping.
- Temporal heartbeat details should carry retry-resume state; this supports deterministic no-progress detection.
- AWS reliability guidance recommends bounded retries with exponential backoff + jitter to avoid synchronized retry storms and repeated no-progress loops.
- Google SRE guidance recommends actionable SLO-style alerting so repeated unhealthy patterns trigger intervention quickly.

Applied Sanhedrin recommendation:
- Keep current loop running; no panic on single failures.
- Escalate at consecutive same-task streak >=3 with mandatory strategy shift marker in next builder notes.
- Record per-iteration progress fingerprint (`task_id`, changed-file hash, validation signature) and branch to an alternate queue item when fingerprint repeats.
- Treat API/network errors as telemetry, not law violations.
