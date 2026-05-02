# CRITICAL: Builder loop liveness failure

- TempleOS heartbeat stale: 68213s (>10m)
- holyc-inference heartbeat stale: 67316s (>10m)
- Sanhedrin heartbeat fresh: 4s
- Restart attempts via required `ssh localhost nohup` command failed: `Could not resolve hostname localhost: -65563`
- `automation/enforce-laws.sh`: `enforce-laws: 0 violations`

Other checks:
- Law 5 code output: TempleOS=10, holyc-inference=7 (pass)
- Law 1 non-HolyC core hits: 0
- Law 2 network diff hits (TempleOS HEAD~3): 0
- Law 4 float/double tokens in inference src: 111 (info)
- Law 6 open CQ count: 9 (below legacy floor, but queue-floor invariant is deprecated by override)
- CI checks blocked (no API reachability)
- Azure compile check blocked (ssh operation not permitted)
