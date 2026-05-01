# CRITICAL: builder liveness stale

- TempleOS heartbeat stale >10 min: `automation/logs/loop.heartbeat`.
- holyc-inference heartbeat stale >10 min: `automation/logs/loop.heartbeat`.
- Restart attempts via `ssh localhost` and `ssh 127.0.0.1` failed in this sandbox (`Could not resolve hostname localhost`, `Operation not permitted`).
- Sanhedrin heartbeat is fresh.
