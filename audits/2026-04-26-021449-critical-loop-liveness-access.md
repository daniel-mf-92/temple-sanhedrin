# CRITICAL audit

- Date: 2026-04-26
- Reason: loop liveness violation.
- Heartbeats missing: `TempleOS/automation/loop.heartbeat`, `holyc-inference/automation/loop.heartbeat`, `temple-sanhedrin/automation/loop.heartbeat`.
- Loop logs stale: TempleOS `317292s`, inference `317226s`, sanhedrin `76173s`.
- Restart attempts via required path failed: `ssh ... localhost` => `Could not resolve hostname localhost: -65563`.
- Fallback `ssh 127.0.0.1` blocked: `Operation not permitted`.
- Code-vs-doc signal: TempleOS last5 `.HC/.sh`=`5`; inference last5 `.HC`=`1` (`.HC/.sh/.py`=`17`).
- Policy/law quick checks: no non-HolyC core files, no network-diff hits, open CQ count `58`, secure-local/IOMMU/quarantine/trinity controls present.
- CI and VM checks blocked by network sandbox (`api.github.com` unreachable; SSH to Azure VM not permitted).
