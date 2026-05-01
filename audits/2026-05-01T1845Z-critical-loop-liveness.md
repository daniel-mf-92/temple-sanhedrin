# CRITICAL
- enforce-laws: 0 violations
- liveness: TempleOS and holyc-inference heartbeats stale (>10 min)
- restart: blocked in this sandbox (`ssh` denied; no write permission to builder repo logs)
- code signal: TempleOS `.HC/.sh` last5=10; holyc `.HC` last5=2
- policy checks: secure-local/quarantine/IOMMU/Book-of-Truth + Trinity/split-plane/attestation/policy-digest all present
- external checks blocked: GitHub Actions API/`gh`, Gmail MCP, Azure VM SSH
