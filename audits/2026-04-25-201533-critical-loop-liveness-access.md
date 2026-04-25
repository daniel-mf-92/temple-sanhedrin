# Sanhedrin Audit (CRITICAL)

- Loop liveness CRITICAL: heartbeat files missing for TempleOS, holyc-inference, and temple-sanhedrin; loop logs stale beyond 10-minute window (mod=295702s, inf=295636s, san=54583s).
- Restart attempts via required `ssh localhost` contract failed in this environment: `Could not resolve hostname localhost: -65563`.
- Builders are stale in central DB (latest modernization/inference entries dated 2026-04-23) though latest recorded statuses are `pass` with code files.
- Law 5 code-output checks pass: modernization last-5 `.HC/.sh` count=6; inference last-5 `.HC` count=1.
- Law checks: Law1 non-HolyC core hits=0; Law2 network diff hits=0; Law4 float/F32/F64 hits=111 (informational baseline); Law6 open `CQ` count=58 (>=25).
- Secure-local/GPU/Trinity/split-plane checks: no policy drift or bypass evidence detected in controlling docs.
- CI and VM checks blocked by sandbox network restrictions:
  - `gh run list` for both repos failed (`error connecting to api.github.com`).
  - Azure VM compile DB check failed (`ssh ... Operation not permitted`).
  - Gmail failure-notification check blocked (`user cancelled MCP tool call`).
