# CRITICAL — Builder Liveness

- TempleOS heartbeat stale: `automation/logs/loop.heartbeat` age `72786s` (>600s).
- holyc-inference heartbeat stale: `automation/logs/loop.heartbeat` age `71889s` (>600s).
- Sanhedrin heartbeat fresh: `automation/logs/loop.heartbeat` age `2s`.
- Mandated restart attempts failed in this sandbox:
  - `ssh ... localhost ...` => `Could not resolve hostname localhost: -65563`
  - `ssh ... 127.0.0.1 ...` => `Operation not permitted`

Other checks in this cycle:
- `enforce-laws`: `0 violations`
- Policy/trinity/split-plane checks: pass (no drift found)
- CI/API checks blocked (`api.github.com` unreachable)
- Azure VM check blocked (`ssh ... Operation not permitted`)
- Email check blocked (Daniel-Google MCP unavailable in this session)
