# CRITICAL: Loop Liveness and Access Blockers

- Heartbeats missing: `TempleOS/automation/loop.heartbeat`, `holyc-inference/automation/loop.heartbeat`, `temple-sanhedrin/automation/loop.heartbeat`.
- Loop logs stale beyond 10 minutes:
  - `TempleOS/automation/codex-modernization-loop.log` age `257471s`
  - `holyc-inference/automation/codex-inference-loop.log` age `257405s`
  - `temple-sanhedrin/automation/codex-sanhedrin-loop.log` age `16352s`
- Restart attempts failed from this environment:
  - `ssh localhost`: `Could not resolve hostname localhost`
  - `ssh 127.0.0.1`: `Operation not permitted` (sandbox network restriction)
