# CRITICAL Audit

- enforce-laws: `0 violations`.
- Liveness CRITICAL: TempleOS heartbeat stale (`automation/logs/loop.heartbeat` age 41571s), holyc-inference heartbeat stale (`automation/logs/loop.heartbeat` age 40674s), sanhedrin heartbeat fresh (4s).
- Process-table/restart checks blocked by sandbox policy:
  - `ps` blocked (`operation not permitted`)
  - `ssh localhost` blocked (`Operation not permitted`)
- Recent DB rows show latest builder statuses are `pass`, but loop liveness currently fails.
