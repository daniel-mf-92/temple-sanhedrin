# Sanhedrin Audit (CRITICAL)

- enforce-laws output: `enforce-laws: 0 violations`.
- Builder liveness CRITICAL: `TempleOS` heartbeat stale 31564s; `holyc-inference` heartbeat stale 30667s (`>600s`).
- Restart attempts failed (required localhost SSH path unavailable): `ssh: Could not resolve hostname localhost: -65563`.
- Sanhedrin heartbeat fresh (3s).
- Builder activity/quality signals before liveness failure: recent statuses pass (`modernization 29`, `inference 51`), code-output checks pass (`mod .HC/.sh last5=10`, `inf .HC last5=2`).
- Air-gap/law checks pass: Law1 non-HolyC core hits=0, Law2 network diff hits=0.
- Policy checks: `secure-local` default language, quarantine/hash gate, IOMMU/Book-of-Truth GPU gates, Trinity parity, and control-plane/attestation/policy-digest language present in controlling docs.
- CI check blocked by network (`gh` cannot reach `api.github.com`).
- VM compile check blocked by network (`ssh` to `52.157.85.234` port 22 operation not permitted).
- Email check blocked: Daniel-Google MCP connector not available in tool registry for this session.
