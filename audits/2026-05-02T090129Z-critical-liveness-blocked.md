# CRITICAL: builder loop liveness

- TempleOS heartbeat stale: 84671s (`automation/logs/loop.heartbeat`)
- holyc-inference heartbeat stale: 83774s (`automation/logs/loop.heartbeat`)
- sanhedrin heartbeat fresh: 4s
- Restart attempt failed:
  - `ssh ... localhost ...` -> `Could not resolve hostname localhost: -65563`
  - `ssh ... 127.0.0.1 ...` -> `connect to host 127.0.0.1 port 22: Operation not permitted`
- Enforcement pre-check: `bash automation/enforce-laws.sh` -> `enforce-laws: 0 violations`
