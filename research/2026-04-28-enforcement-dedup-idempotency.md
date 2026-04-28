# Enforcement dedup/idempotency notes (2026-04-28)

Trigger: repeated `enforce-laws` pattern (`DETECT` + `ALREADY-CLEAN`) for the same commit/file across many iterations.

Findings (web):
- Google SRE alerting guidance emphasizes actionable signals over repeated noise; duplicate/no-op alerts degrade operator response quality.
- PagerDuty event model uses stable `dedup_key` to collapse repeat triggers for the same incident context.
- Prometheus Alertmanager’s core model explicitly uses dedup/grouping/inhibition to suppress repeat notifications for already-known conditions.

Sanhedrin application:
- Add a stable incident fingerprint for enforcement events: `{repo,sha,law,detail}`.
- If the same fingerprint was already marked `ALREADY-CLEAN` within a cooldown window, suppress severity escalation and emit one summarized heartbeat note instead of repeating warning payloads.
- Keep first detection visible; suppress only repeated no-op detections.
- Track counter metric `enforcement_dedup_suppressed_total` to verify noise reduction without hiding new violations.

Candidate implementation hooks:
- `automation/enforce-laws.sh`: write fingerprint + timestamp cache on `ALREADY-CLEAN`.
- `audits/enforcement.log` parser: fold duplicate fingerprints in rolling 24h summary.
