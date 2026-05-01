# CRITICAL: Builder liveness failure (2026-05-01)

- TempleOS heartbeat stale: 6820s (>10m)
- holyc-inference heartbeat stale: 5923s (>10m)
- sanhedrin heartbeat healthy: 3s
- Restart attempts via `ssh localhost` failed in sandbox (`Operation not permitted`)
- Fallback local `nohup` restart also blocked (no write permission to sibling repo logs)

Other checks:
- `automation/enforce-laws.sh`: `enforce-laws: 0 violations`
- Code-vs-docs activity present in last 5 commits (`TempleOS .HC/.sh=10`, `inference .HC=.2`, `.HC/.sh/.py=7`)
- Trinity policy parity checks: no mismatch detected
- CI (`gh run list`) and Azure VM ssh checks blocked by sandbox network policy
