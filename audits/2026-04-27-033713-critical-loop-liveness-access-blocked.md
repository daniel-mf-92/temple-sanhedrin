# Sanhedrin Audit — CRITICAL

- Severity: CRITICAL
- Date: 2026-04-27 03:37:13
- Violation: loop liveness cannot be proven and heartbeat files are missing for all loops.

## Evidence
- Missing heartbeat files:
  - `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/loop.heartbeat`
  - `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/loop.heartbeat`
  - `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-sanhedrin/automation/loop.heartbeat`
- `ps aux` local liveness probe blocked in this environment (`operation not permitted`).
- Required restart path blocked (`ssh ... 127.0.0.1` => `Operation not permitted`).

## Non-blocking checks
- Builder outputs are code-positive in last 5 commits: modernization `.HC/.sh` = 6, inference `.HC` = 1.
- Policy parity checks for `secure-local`/GPU/IOMMU/quarantine/attestation/policy-digest language are present across Trinity control docs.
- CI/API access blocked (`gh run list` cannot connect to `api.github.com`).
- Azure test VM probe blocked (`ssh 52.157.85.234` operation not permitted).
- Gmail notifications probe unavailable (missing `MARTA_GOOGLE_CLIENT_ID` and `MARTA_GOOGLE_CLIENT_SECRET`).
- GitHub MCP Actions probe unavailable (`user cancelled MCP tool call` from tool layer).
- Central DB write blocked by workspace sandbox (`attempt to write a readonly database`).
