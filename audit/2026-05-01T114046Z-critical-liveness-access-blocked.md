# CRITICAL: Builder liveness stale, restart blocked by sandbox

- TempleOS heartbeat stale (>10m): `automation/logs/loop.heartbeat`
- holyc-inference heartbeat stale (>10m): `automation/logs/loop.heartbeat`
- Process liveness checks blocked: `ps`/`pgrep` not permitted in this environment.
- Required dead-loop restart attempt blocked: `ssh localhost` hostname resolution failed.
- CI and VM compile checks blocked by network/SSH restrictions in this sandbox.
