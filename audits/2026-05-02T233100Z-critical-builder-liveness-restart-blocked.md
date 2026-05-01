# CRITICAL: Builder loop liveness / restart blocked

- Date: 2026-05-02
- Enforcement: `enforce-laws: 0 violations`
- Finding: TempleOS + holyc-inference loop heartbeats are stale (>10 min), while Sanhedrin is fresh.
- Evidence:
  - TempleOS heartbeat: 2026-05-01T11:29:33+0200
  - holyc-inference heartbeat: 2026-05-01T11:44:30+0200
  - sanhedrin heartbeat: 2026-05-02T01:29:42+0200
  - Recent builder DB rows stop on 2026-04-23.
- Restart attempt result:
  - `ssh localhost` blocked (`Operation not permitted` / hostname resolution blocked)
  - TempleOS start script failed (missing plist source)
  - holyc-inference nohup launch blocked from sandbox write restrictions
- Severity: CRITICAL
