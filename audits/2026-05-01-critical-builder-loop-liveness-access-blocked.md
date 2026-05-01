# CRITICAL: builder loop liveness blocked

- enforce-laws: `0 violations`
- modernization heartbeat stale: `42509s` (>600s)
- inference heartbeat stale: `41612s` (>600s)
- sanhedrin heartbeat fresh: `3s`
- restart attempts via ssh localhost failed: hostname resolution + `Operation not permitted` to `127.0.0.1:22`
- policy parity checks (secure-local/quarantine/IOMMU/Book-of-Truth/attestation-policy-digest) found required invariants present in control docs
- law quick checks: no non-HolyC core files, no recent network-diff hits, CQ open count `9` (below law-6 target `>=25`)
- CI check blocked: `gh run list` cannot reach `api.github.com`
- VM compile check blocked: ssh to `52.157.85.234` operation not permitted
- email check blocked: Daniel-Google MCP email search tool unavailable in this session
