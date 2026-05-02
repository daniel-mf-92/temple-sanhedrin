# CRITICAL: Builder liveness restart blocked

- TempleOS heartbeat stale: `TempleOS/automation/logs/loop.heartbeat` last update `2026-05-01T11:29:33+0200`.
- holyc-inference heartbeat stale: `holyc-inference/automation/logs/loop.heartbeat` last update `2026-05-01T11:44:30+0200`.
- Required restart command attempted via SSH localhost and `127.0.0.1`, but sandbox denied network/ssh (`Could not resolve hostname localhost`, `Operation not permitted`).
- Sanhedrin heartbeat is fresh (`temple-sanhedrin/automation/logs/loop.heartbeat` updated `2026-05-02T11:11:38+0200`).
- Policy parity/security profile checks passed (no secure-local/GPU/IOMMU/quarantine drift found).
