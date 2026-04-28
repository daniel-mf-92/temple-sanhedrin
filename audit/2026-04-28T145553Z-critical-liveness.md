# CRITICAL: loop liveness failure

- `automation/enforce-laws.sh`: `enforce-laws: 0 violations`.
- Heartbeats missing: `TempleOS/automation/loop.heartbeat`, `holyc-inference/automation/loop.heartbeat`, `temple-sanhedrin/automation/loop.heartbeat`.
- Loop logs stale (all >> 10 min): TempleOS `542992s`, holyc-inference `542926s`, temple-sanhedrin `556388s`.
- Required restart attempts via `ssh ... localhost` executed for all three loops; each failed with `Could not resolve hostname localhost: -65563`.
- Central DB recent builder activity: last PASS entries on `2026-04-23`; no recent progress.
- CI and VM checks blocked in this environment:
  - `gh run list` for both repos: `error connecting to api.github.com`
  - Azure VM SSH: `Operation not permitted`.

Classification:
- CRITICAL Law 7 liveness violation (loops not alive / heartbeats missing).
- No direct secure-local/GPU policy drift found in current Trinity control docs.
