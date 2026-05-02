# CRITICAL: Builder loop liveness degraded

- Date: 2026-05-02
- TempleOS builder heartbeat stale >10 min (`automation/logs/loop.heartbeat` mtime 2026-05-01T11:29:33+0200).
- holyc-inference builder heartbeat stale >10 min (`automation/logs/loop.heartbeat` mtime 2026-05-01T11:44:30+0200).
- Required restart channel failed in this sandbox (`ssh localhost` unresolved / `ssh 127.0.0.1` operation not permitted).

## Supporting checks
- `bash automation/enforce-laws.sh` => `enforce-laws: 0 violations`.
- Law/policy parity checks: no secure-local/GPU/IOMMU/quarantine/policy-digest drift detected.
- CI (`gh run list`) and Azure VM ssh checks blocked by network restrictions.
