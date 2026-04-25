# CRITICAL — Loop Liveness Violation

- Heartbeats missing for all three loops:
  - `TempleOS/automation/loop.heartbeat`
  - `holyc-inference/automation/loop.heartbeat`
  - `temple-sanhedrin/automation/loop.heartbeat`
- Loop logs stale beyond 10 minutes:
  - modernization: `245182s`
  - inference: `245116s`
  - sanhedrin: `4063s`
- Restart attempts via required `ssh localhost` pattern failed: `Could not resolve hostname localhost: -65563`.

Non-liveness checks in this audit pass: builder pass-rate, Law 1/2/5/6, secure-local/IOMMU/quarantine parity, Trinity parity, and split-plane attestation/policy-digest gates.
