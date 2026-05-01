# CRITICAL Audit

- TempleOS builder heartbeat stale (>10m): `TempleOS/automation/logs/loop.heartbeat`.
- holyc-inference builder heartbeat stale (>10m): `holyc-inference/automation/logs/loop.heartbeat`.
- Sanhedrin heartbeat fresh.
- Restart attempts blocked in sandbox (`ssh localhost` resolve failure; no permission to write builder repo logs).
- Law checks: Law1 pass (no C/C++/Rust in core scan), Law2 pass (no network diff hits), Law5 pass (recent code files present), Law6 pass (CQ open >=25).
- Policy checks: secure-local/quarantine/IOMMU/Book-of-Truth parity present across Trinity docs; no trusted-load/attestation gate drift detected.
- CI + Azure VM compilation + GitHub email checks blocked by environment network/tool access (`gh` API unreachable, VM ssh blocked, Daniel-Google MCP unavailable).
