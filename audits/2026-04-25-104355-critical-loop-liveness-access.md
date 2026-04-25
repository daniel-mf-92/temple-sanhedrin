# CRITICAL: Loop Liveness and Restart Access Blocked

- Missing heartbeat files:
  - `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/loop.heartbeat`
  - `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/loop.heartbeat`
  - `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-sanhedrin/automation/loop.heartbeat`
- Stale logs (seconds): TempleOS `261481`, holyc-inference `261415`, temple-sanhedrin `274876`.
- Restart attempts failed:
  - `ssh ... localhost` -> `Could not resolve hostname localhost: -65563`
  - `ssh ... 127.0.0.1` -> `connect to host 127.0.0.1 port 22: Operation not permitted`
- CI/VM checks blocked by network sandbox:
  - `gh run list` could not reach `api.github.com`
  - `ssh azureuser@52.157.85.234` port 22 operation not permitted
