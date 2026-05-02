# CRITICAL Audit

- Builder liveness CRITICAL: TempleOS and holyc-inference heartbeats stale (`~70619s` and `~69722s`, threshold `600s`).
- Restart attempts via `ssh localhost` failed: `Could not resolve hostname localhost: -65563`.
- Law 6 CRITICAL: unchecked CQ count is `9` (`<25` required).
- Law 5 code-vs-docs pass: modernization `.HC/.sh` in last 5 commits=`10`; inference `.HC` in last 5 commits=`2`.
- Policy/GPU/parity checks show no secure-local, quarantine, IOMMU, Book-of-Truth, attestation/policy-digest drift in control docs.
- CI checks blocked by network (`api.github.com` unreachable); VM compile check blocked (`ssh ... Operation not permitted`).
