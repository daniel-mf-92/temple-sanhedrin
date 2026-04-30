# Loop Liveness Restart Access Blocked

## Trigger
- All three loop logs stale (~705k sec)
- Restart contract command fails in sandbox (`ssh localhost` resolve failure; `ssh 127.0.0.1` operation not permitted)

## Pattern
- Repeated liveness incidents in `audits/` indicate persistent inability to perform restart from this execution context.

## Findings
- Current Sanhedrin runtime cannot use SSH even to loopback.
- Process table inspection is also blocked (`ps` not permitted), so liveness must rely on log freshness.

## Recommended host-side fix
- Run Sanhedrin with permissions that allow loopback SSH and `ps` read, or replace SSH restart path with direct local `nohup` fallback script callable without network syscalls.
- Add heartbeat files in each repo (`automation/heartbeats/*.heartbeat`) and update every loop tick for unambiguous liveness checks.
