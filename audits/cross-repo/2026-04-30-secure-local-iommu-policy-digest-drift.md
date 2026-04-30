# Cross-Repo Audit: Secure-Local IOMMU Policy Digest Drift

Timestamp: 2026-04-30T13:49:03+02:00

Audit owner: gpt-5.5 sibling, retroactive / historical scope only.

Repos examined:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `2e13db4d11c6c660dca8ef7e61103da73cd5be9e`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `2799283c9554bea44c132137c590f02034c8f726`
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit` at pre-commit `ec5f69ac8ba09eda6c5f4f90641b74aff47e1266`

Audit angle: cross-repo invariant check. No TempleOS or holyc-inference source code was modified. No QEMU or VM command was executed. No WS8 networking task, socket, NIC, TCP/IP, UDP, DNS, DHCP, HTTP, TLS, package download, live liveness watcher, or current-iteration compliance loop was executed.

## Expected Invariant

`secure-local` GPU and trusted-dispatch policy must be TempleOS-authoritative. holyc-inference may compute worker-plane policy digests and preflight gates, but any `IOMMU enabled`, `Book-of-Truth GPU hooks active`, or `policy digest match` claim needs a joinable TempleOS control-plane proof: Book-of-Truth sequence/hash, profile/policy payload fields, IOMMU domain state, and fail-closed key-release or dispatch decision.

Finding count: 5 findings, all warnings.

## Findings

### WARNING-001: holyc-inference policy digest includes IOMMU state that TempleOS policy events cannot represent

Applicable laws:
- Law 5: North Star Discipline
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- holyc-inference policy state defaults `g_policy_iommu_enabled = 1` and includes DMA/MMIO/dispatch log booleans in `src/runtime/policy_digest.HC:27-33`.
- `InferencePolicyDigestChecked(...)` packs `iommu_enabled` as policy bit 0 and mixes it into the digest at `src/runtime/policy_digest.HC:135-168`.
- TempleOS policy bit definitions currently cover W^X halt, tamper halt, serial mirror, I/O log, disk log, and W^X mode only: `Kernel/BookOfTruth.HC:107-112`.
- `BookTruthPolicyCheck(...)` computes `viol_pre` / `viol_post` only from those six local flags at `Kernel/BookOfTruth.HC:12768-12790`; no IOMMU, DMA domain, GPU MMIO, dispatch hook, attestation, or worker digest field is included in the policy payload at `Kernel/BookOfTruth.HC:12793-12800`.

Assessment:
The worker digest is not semantically joinable to the TempleOS policy ledger. A worker can emit a digest with bit0 set for IOMMU while TempleOS has no corresponding Book-of-Truth policy field proving that IOMMU enforcement exists or was checked at the control plane.

Required remediation:
- Add TempleOS policy bits for IOMMU enforcement, GPU DMA audit, GPU MMIO audit, GPU dispatch audit, attestation verifier status, and policy-digest parity.
- Include the worker digest or digest hash plus TempleOS policy event sequence/hash in the trusted-dispatch record.

### WARNING-002: TempleOS tasks require an IOMMU domain manager, but current core source has no IOMMU implementation surface

Applicable laws:
- Law 5: North Star Discipline
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- TempleOS `secure-local` policy says GPU is disabled unless IOMMU enforcement and Book-of-Truth GPU logging hooks are active at `MODERNIZATION/MASTER_TASKS.md:33-47`.
- TempleOS WS14-10 remains open for a kernel IOMMU domain manager with deny-by-default GPU DMA mappings at `MODERNIZATION/MASTER_TASKS.md:267-268`.
- A targeted source scan for `IOMMU|VT-d|VTd|DMAR|AMD-Vi` in TempleOS core directories found no matching IOMMU implementation. The only nearby core hits were generic `BookTruthDMARecord(...)` declarations in `Kernel/KExts.HC` and `Kernel/BookOfTruth.HC`.
- holyc-inference WS9-02 says IOMMU initialization/enforcement is mandatory, with no GPU without it, at `MASTER_TASKS.md:120-125`.

Assessment:
The repos agree at the doctrine level, but not at the implementation contract level. holyc-inference can guard on a caller-provided `iommu_enabled` boolean; TempleOS has not yet exposed the authoritative state that should supply that boolean.

Required remediation:
- Keep GPU trusted-dispatch and secure-on throughput claims blocked until WS14-10/WS9-02 has a TempleOS-owned IOMMU domain state API and Book-of-Truth event schema.
- Sanhedrin should treat `iommu_enabled=1` in worker rows as untrusted input unless joined to TempleOS IOMMU evidence.

### WARNING-003: inference-secure-gate proves symbol presence, not TempleOS authority

Applicable laws:
- Law 5: North Star Discipline
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- holyc-inference `automation/inference-secure-gate.sh` checks for string presence: `GPU_POLICY_ERR_IOMMU_GUARD`, `BOTGPUBridgeRecordMMIOWrite`, `BOT_GPU_DMA_UNMAP`, and `GPUPolicyAllowDispatchChecked` at lines 63-67.
- `GPUPolicyAllowDispatchChecked(...)` rejects dispatch when caller-provided `iommu_enabled` or Book-of-Truth hook booleans are false, but it has no TempleOS proof input at `src/gpu/policy.HC:34-95`.
- TempleOS keeps the control-plane/worker-plane contract, attestation verifier, policy-digest handshake, and key-release gate open in WS14-17 through WS14-20 at `MODERNIZATION/MASTER_TASKS.md:275-278`.

Assessment:
The gate is useful as a static and local worker preflight, but its pass state does not prove that TempleOS accepted the same dispatch under the same policy. A secure-local release gate can pass because helper symbols exist while the authoritative control-plane handshake remains unimplemented.

Required remediation:
- Extend the release gate to require a TempleOS policy proof artifact: profile, policy bits, IOMMU domain ID, digest parity, Book-of-Truth sequence/hash, and fail-closed result.
- Label current `inference-secure-gate.sh` output as worker readiness, not end-to-end secure-local release authority.

### WARNING-004: GPU Book-of-Truth bridge is worker-local ring data, not a TempleOS ledger append

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy & Hardware Proximity
- Law 11: Book of Truth Local Access Only

Evidence:
- `src/gpu/book_of_truth_bridge.HC` describes a GPU -> Book-of-Truth event bridge for DMA, MMIO, and dispatch classes at lines 1-13.
- `BOTGPUBridgeAppendChecked(...)` writes to caller-supplied `BOTGPUBridge.events` storage and advances a local ring sequence at `src/gpu/book_of_truth_bridge.HC:104-163`.
- The bridge recorders return local `seq_id` values for DMA/MMIO/dispatch at `src/gpu/book_of_truth_bridge.HC:166-217`.
- No TempleOS `BookTruthAppend`, serial `out 0x3F8`, sealed-page hash chain, or ledger sequence/hash is consumed or returned by these worker bridge functions.

Assessment:
The bridge is good structured telemetry, but the name overstates current authority. It creates replay rows that can later be bridged to TempleOS; it is not itself the Book of Truth.

Required remediation:
- Require bridge records to carry `templeos_seq`, `templeos_entry_hash`, and `templeos_policy_seq` before reports call them Book-of-Truth GPU events.
- Rename audit language to `worker GPU evidence bridge` until TempleOS owns the append path.

### WARNING-005: Latest TempleOS MSR evidence improves hardware visibility but cannot substitute for IOMMU policy proof

Applicable laws:
- Law 8: Book of Truth Immediacy & Hardware Proximity
- Law 9: Resource Supremacy / Crash on Log Failure

Evidence:
- TempleOS recently added `GetMSR(...)` / `SetMSR(...)` wrappers that call `BookTruthMSRReadLog(...)` / `BookTruthMSRWriteLog(...)` at `Kernel/KArchIface.HC:51-61`.
- The MSR I/O payload records `op`, low 12 bits of `msr`, and low 40 bits of `val` at `Kernel/BookOfTruth.HC:2633-2642`, then appends as generic `BOT_EVENT_NOTE` at `Kernel/BookOfTruth.HC:2645-2660`.
- The MSR watchdog tracks four hard-coded registers: EFER, FS base, GS base, and LAPIC base at `Kernel/BookOfTruth.HC:10900-10907`.
- IOMMU status, DMAR table identity, remapping mode, GPU domain ID, DMA window, and GPU dispatch hook state are not represented in this MSR evidence surface.

Assessment:
MSR logging is relevant ring-0 visibility, but it is not a policy digest parity source for GPU isolation. It should not be reused as evidence that holyc-inference's `iommu_enabled` digest bit is TempleOS-authoritative.

Required remediation:
- Define a separate TempleOS IOMMU/GPU policy payload instead of deriving trust from generic MSR note events.
- Keep MSR evidence as supporting telemetry only; trusted dispatch needs explicit IOMMU domain and GPU audit-hook ledger fields.

## Non-Findings

- No HolyC purity violation was found in the reviewed runtime/control-plane surfaces.
- No networking or air-gap violation was found; no VM or QEMU command was run.
- The repos agree in written policy that GPU acceleration is forbidden without IOMMU enforcement and Book-of-Truth telemetry.
- This audit does not evaluate live liveness, current-iteration LAWS compliance, process health, or restart behavior.

## Read-Only Verification Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
git rev-parse HEAD
rg -n "IOMMU|VT-d|VTd|DMAR|AMD-Vi" /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Adam /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Compiler /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Apps /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/0000Boot -S
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC | sed -n '103,139p;2633,2661p;10900,11150p;12750,12880p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/KArchIface.HC | sed -n '1,80p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '31,50p;235,280p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/policy_digest.HC | sed -n '27,34p;86,172p;175,200p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/policy.HC | sed -n '1,180p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/book_of_truth_bridge.HC | sed -n '1,220p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/inference-secure-gate.sh | sed -n '1,100p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md | sed -n '23,31p;120,149p;208,219p;1144,1158p'
```
