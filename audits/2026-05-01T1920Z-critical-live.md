# Sanhedrin Critical Audit — 2026-05-01T19:20Z

- CRITICAL: builder loop liveness failed.
- TempleOS heartbeat stale: `automation/logs/loop.heartbeat` age 30529s (>600s).
- holyc-inference heartbeat stale: `automation/logs/loop.heartbeat` age 29632s (>600s).
- sanhedrin heartbeat fresh: age 3s.
- Restart attempts blocked in this sandbox:
  - `ssh ... localhost`: `Could not resolve hostname localhost: -65563`
  - `ssh ... 127.0.0.1`: `Operation not permitted`
- `ps` liveness probe blocked by sandbox: `operation not permitted: ps`.
