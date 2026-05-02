# Sanhedrin CRITICAL Audit (2026-05-02T07:16:41Z)

- Severity: CRITICAL
- Trigger: Builder loop liveness failure
- TempleOS heartbeat age: 78428s (>600)
- holyc-inference heartbeat age: 77531s (>600)
- sanhedrin heartbeat age: 3s
- Restart attempts: failed (ssh localhost unresolved; ssh 127.0.0.1 operation not permitted in sandbox)
- Stale loop locks with dead PIDs detected in both builders
- Law 5 code output: modernization=10, inference_hc=2, inference_hc_sh_py=7
- Law 1 non-HolyC core hits: 0
- Law 2 network diff hits: 0
- Law 4 float/F32/F64 references: 111 (info)
- Law 6 open CQ count: 9 (queue-floor deprecated by override)
- Policy checks: secure-local default/quarantine/IOMMU/Book-of-Truth parity present; no drift detected
- CI/email/azure checks: blocked in this environment (no outbound API/SSH, MCP call cancelled)
