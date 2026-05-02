# CRITICAL — Liveness Blocked

- TempleOS heartbeat stale (>10m): `automation/logs/loop.heartbeat`.
- holyc-inference heartbeat stale (>10m): `automation/logs/loop.heartbeat`.
- sanhedrin heartbeat fresh.
- Required restart attempts via `ssh ... localhost` failed with `Could not resolve hostname localhost: -65563`.
- CI status checks (`gh run list`) and Azure VM compile check were execution-blocked by network restrictions in this environment.
