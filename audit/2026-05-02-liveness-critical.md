# CRITICAL — Loop Liveness Failure (2026-05-02)

- TempleOS heartbeat stale: 84290s (`TempleOS/automation/logs/loop.heartbeat`)
- holyc-inference heartbeat stale: 83393s (`holyc-inference/automation/logs/loop.heartbeat`)
- sanhedrin heartbeat fresh: 2s (`temple-sanhedrin/automation/logs/loop.heartbeat`)
- Restart attempts blocked by sandbox:
  - `ssh localhost` failed: host resolution error `-65563`
  - `ssh 127.0.0.1` failed: `Operation not permitted`

Impact:
- Builder activity in `temple-central.db` is stale (latest builder rows at 2026-04-23).
- Sanhedrin cannot restore dead loops from current sandbox.
