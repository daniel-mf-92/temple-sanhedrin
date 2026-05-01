# CRITICAL: Liveness recovery blocked

- Date: $(date -u +%FT%TZ)
- Enforcement: `bash automation/enforce-laws.sh` => `enforce-laws: 0 violations`
- Liveness: TempleOS + holyc-inference heartbeat files are stale (>10 min)
- Required recovery path (`ssh localhost ...`) is blocked in this environment (`Operation not permitted` / host resolution blocked)
- Equivalent local restart attempt also blocked from writing cross-repo loop logs by sandbox write scope
- Policy/law scans: no secure-local/GPU/trinity drift detected; trinity policy sync check passed (21/21)
- CI + Azure VM + email checks: blocked by network/auth limits in this environment

Immediate host-side action needed: run the documented localhost SSH restart commands outside sandbox, then verify heartbeats < 600s.
