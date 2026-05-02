# CRITICAL: builder loop liveness

- TempleOS heartbeat stale (>10m): `automation/logs/loop.heartbeat`.
- holyc-inference heartbeat stale (>10m): `automation/logs/loop.heartbeat`.
- Sanhedrin heartbeat fresh.
- Restart attempts blocked in sandbox:
  - `ssh ... localhost` -> host resolution failure (`-65563`)
  - `ssh ... 127.0.0.1` -> `Operation not permitted`
  - direct `nohup` restart -> write denied outside writable roots
