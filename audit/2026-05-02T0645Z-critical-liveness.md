# CRITICAL — Liveness Failure

- `bash automation/enforce-laws.sh`: `enforce-laws: 0 violations`
- Builder heartbeat files stale (`automation/logs/loop.heartbeat`):
  - TempleOS: `2026-05-01T11:29:33+0200`
  - holyc-inference: `2026-05-01T11:44:30+0200`
- Restart attempts failed:
  - `ssh ... localhost ...`: `Could not resolve hostname localhost: -65563`
  - `ssh ... 127.0.0.1 ...`: `Operation not permitted`
- Policy/law checks: no secure-local/GPU/parity drift detected; no network-path violation detected.
- CI/VM checks blocked by sandbox/network restrictions (`api.github.com` unreachable; Azure SSH not permitted).
