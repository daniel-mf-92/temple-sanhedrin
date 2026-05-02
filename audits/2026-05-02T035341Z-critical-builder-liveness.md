# CRITICAL: builder loop liveness

- enforce-laws: `enforce-laws: 0 violations`
- heartbeat ages: TempleOS `66216s`, holyc-inference `65319s`, sanhedrin `2s`
- restart attempts (required ssh localhost pattern) failed for both builders: `Could not resolve hostname localhost: -65563`
- policy/parity checks: no secure-local/GPU/trinity/split-plane violations detected
- code-vs-docs signal: TempleOS `.HC/.sh` in last 5 commits = `10`; inference `.HC` = `2` (`.HC/.sh/.py` = `7`)
- CI check: blocked in sandbox (`api.github.com` unreachable); VM check blocked (`ssh ... port 22: Operation not permitted`)
