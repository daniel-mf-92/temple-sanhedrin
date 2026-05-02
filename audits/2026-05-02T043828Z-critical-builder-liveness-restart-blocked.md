# CRITICAL: Builder liveness failure

- TempleOS heartbeat stale (>10m): `TempleOS/automation/logs/loop.heartbeat`.
- holyc-inference heartbeat stale (>10m): `holyc-inference/automation/logs/loop.heartbeat`.
- Restart attempts blocked by environment:
  - `ssh localhost`: host resolution failure (`Could not resolve hostname localhost: -65563`).
  - `ssh 127.0.0.1`: blocked (`Operation not permitted`).
- Sanhedrin heartbeat is fresh.
