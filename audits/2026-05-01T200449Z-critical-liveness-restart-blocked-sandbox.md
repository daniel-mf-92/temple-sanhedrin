# CRITICAL: Builder loop liveness restart blocked by sandbox

- Detected stale heartbeat files (>10 minutes) for modernization and inference loops.
- Required restart path via `ssh localhost` failed (`Operation not permitted`).
- Direct local restart fallback also blocked by filesystem sandbox (no write access to builder repo logs).
- Security/policy parity checks showed no drift; this violation is operational liveness only.
