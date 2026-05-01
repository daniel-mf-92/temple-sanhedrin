## CRITICAL: builder loop liveness blocked

- Time: 2026-05-01T11:08Z
- TempleOS heartbeat stale: 5739s
- holyc-inference heartbeat stale: 4842s
- sanhedrin heartbeat fresh: 3s
- Restart attempts via required `ssh localhost` path failed:
  - `Could not resolve hostname localhost`
  - `ssh 127.0.0.1 ...` blocked with `Operation not permitted`
- Other checks:
  - Law 5 code-output checks: pass (TempleOS `.HC/.sh`=10, inference `.HC`=2)
  - Trinity secure-local/GPU/IOMMU/quarantine/attestation policy markers: present
  - CI + Azure VM checks: blocked by network/SSH sandbox restrictions
