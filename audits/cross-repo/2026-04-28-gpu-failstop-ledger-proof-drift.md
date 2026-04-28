# Cross-Repo Invariant Audit: GPU Failstop Ledger Proof Drift

- Audit angle: cross-repo invariant checks
- Audit time: `2026-04-28T05:14:12+02:00`
- Auditor: gpt-5.5 sibling, retroactive/deep audit scope
- TempleOS HEAD: `f140a8ab65e67b7acf3c4f44d00f650ee1512d6a`
- holyc-inference HEAD: `b8a4fc8b7dd7cb2175ff3e4e8f051a7d4b19ca7d`
- temple-sanhedrin baseline: `4b1936f4ab25f08aa143c40468bf57294d69e20c`

## Summary

Found 4 findings: 1 critical, 3 warnings.

TempleOS has a concrete failstop path for Book-of-Truth serial liveness: it probes COM1 LSR, records watchdog/dead events, and can halt via `SysHlt` when serial liveness fails. holyc-inference has strong local GPU policy checks, but the reviewed GPU dispatch gates and attestation treat Book-of-Truth hook readiness as caller-supplied booleans. There is still no cross-repo proof tuple binding GPU dispatch permission to a TempleOS Book-of-Truth append sequence, source/event ID, serial liveness status, and halt-on-failure mode.

No TempleOS or holyc-inference source files were modified. No VM, QEMU, or WS8 networking command was executed.

## Finding CRITICAL-001: GPU dispatch can be allowed from booleans without a TempleOS ledger append proof

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy & Hardware Proximity
- Law 9: Resource Supremacy / Crash on Log Failure

Evidence:
- `holyc-inference/src/gpu/policy.HC:34-40` accepts `iommu_enabled`, `bot_dma_log_enabled`, `bot_mmio_log_enabled`, and `bot_dispatch_log_enabled` as scalar inputs.
- `holyc-inference/src/gpu/policy.HC:82-94` allows dispatch when those hook flags are true.
- `holyc-inference/src/gpu/security_perf_matrix.HC:408-467` allows a row when `book_of_truth_gpu_hooks`, `iommu_active`, and `policy_digest_parity` are true.
- `holyc-inference/src/gpu/security_perf_matrix.HC:470-519` allows the fast path when `book_of_truth_gpu_hooks` and other parity flags are true.
- `TempleOS/Kernel/BookOfTruthSerialCore.HC:1218-1226` records `BOT_EVENT_SERIAL_DEAD` and halts via `SysHlt` on failed liveness checks when halt-on-dead is enabled.

Assessment:
The inference side has no reviewed requirement that a true `bot_*` or `book_of_truth_gpu_hooks` flag be accompanied by a TempleOS ledger sequence number, decoded event/source tuple, or serial liveness/halt policy evidence. A caller can provide `1` for hook booleans and unlock dispatch/performance rows without proving that the TempleOS Book of Truth synchronously accepted a GPU record.

Impact:
This is a contract-level Law 8/9 gap. GPU dispatch claims can outrun the only failstop mechanism that is currently concrete in TempleOS. Until the boolean is bound to a TempleOS append proof, Sanhedrin cannot distinguish actual Book-of-Truth-backed GPU telemetry from a local inference-side assertion.

Required remediation:
- Define a cross-repo `BookTruthGpuAppendProof` tuple: `{temple_event_id, temple_source_id, ledger_seq, entry_hash, serial_liveness_ok, halt_on_dead, payload_class}`.
- Make GPU dispatch gates require that tuple, not only boolean hook flags.
- Sanhedrin should reject `book_of_truth_gpu_hooks=1` evidence unless the tuple decodes against TempleOS constants and the serial liveness state is fail-closed.

## Finding WARNING-001: Inference attestation emits GPU hook state without ledger identity

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- `holyc-inference/src/runtime/attestation_manifest.HC:17-30` stores `gpu_dispatch_allowed`, `iommu_active`, and `bot_gpu_hooks_active`.
- `holyc-inference/src/runtime/attestation_manifest.HC:225-240` accepts `bot_gpu_hooks_active` as a binary field.
- `holyc-inference/src/runtime/attestation_manifest.HC:299-316` emits `gpu_dispatch_allowed`, `iommu_active`, and `bot_gpu_hooks_active`.
- `TempleOS/Kernel/BookOfTruth.HC:3-22` currently defines canonical events only through `BOT_EVENT_SERIAL_WATCHDOG`.
- `TempleOS/Kernel/BookOfTruth.HC:79-86` currently defines canonical sources only through `BOT_SOURCE_DISK`.

Assessment:
The attestation manifest can report `bot_gpu_hooks_active=1`, but it does not carry TempleOS event/source IDs, sequence IDs, or hashes. That leaves the manifest weaker than the Book-of-Truth invariant it names.

Required remediation:
- Add ledger identity fields to the manifest before treating GPU hook state as auditable.
- Include canonical TempleOS GPU event/source constants once reserved.
- Require `bot_gpu_hooks_active=1` to include a last observed ledger sequence and entry hash.

## Finding WARNING-002: holyc-inference GPU bridge is transient storage, not a failstop ledger

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 9: Resource Supremacy / Crash on Log Failure

Evidence:
- `holyc-inference/src/gpu/book_of_truth_bridge.HC:47-54` stores GPU events in caller-provided ring state.
- `holyc-inference/src/gpu/book_of_truth_bridge.HC:104-163` appends local GPU events and returns a bridge-local sequence ID.
- `holyc-inference/src/gpu/book_of_truth_bridge.HC:154-155` explicitly says full rings overwrite the oldest event.
- `TempleOS/Kernel/BookOfTruthSerialCore.HC:1218-1226` shows TempleOS' failstop pattern records serial-dead state and halts, rather than silently continuing after a failed record path.

Assessment:
The bridge can be useful as a producer buffer, but its local `seq_id` is not a TempleOS Book-of-Truth sequence. Because it overwrites full rings, it cannot be treated as canonical audit evidence for Law 3 or Law 9.

Required remediation:
- Rename or document the bridge output as pre-ledger evidence only.
- Return both bridge-local sequence and TempleOS ledger sequence after a synchronous append.
- On capacity pressure, block GPU dispatch or fail closed unless the overwritten event has already been sealed into the TempleOS ledger.

## Finding WARNING-003: TempleOS failstop telemetry is serial-focused and does not yet cover GPU producer failure reasons

Applicable laws:
- Law 8: Book of Truth Immediacy & Hardware Proximity
- Law 9: Resource Supremacy / Crash on Log Failure

Evidence:
- `TempleOS/Kernel/BookOfTruth.HC:39-43` defines serial-dead reasons for unknown, append precheck, liveness check, and TX timeout.
- `TempleOS/Kernel/BookOfTruthSerialCore.HC:1136-1155` records watchdog payloads from COM1 LSR and serial transmit readiness.
- `TempleOS/Kernel/BookOfTruthSerialCore.HC:1171-1177` records liveness-check dead events.
- `holyc-inference/src/gpu/book_of_truth_bridge.HC:22-34` defines GPU DMA/MMIO/dispatch event classes and operations.

Assessment:
TempleOS has strong serial liveness evidence, but the reviewed constants do not provide GPU-specific failstop reasons such as DMA append failure, MMIO append failure, dispatch append failure, bridge capacity pressure, or IOMMU proof missing. That means future GPU producer failures would either be invisible or forced into generic serial categories.

Required remediation:
- Reserve GPU-specific failstop reasons and payload markers in TempleOS.
- Add source/event replay fixtures that exercise GPU append failure and capacity-pressure cases.
- Require holyc-inference tests to assert those TempleOS failure reason IDs when GPU hook evidence is unavailable.

## Non-Findings

- No air-gap breach was found or induced by this audit.
- No networking stack, socket, TCP/IP, UDP, DNS, DHCP, HTTP, TLS, or WS8 execution was observed in the audited paths.
- No non-HolyC runtime implementation was introduced by this audit.
- No QEMU/VM command was run.

## Read-Only Verification Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55 rev-parse HEAD
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC | sed -n '1,140p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruthSerialCore.HC | sed -n '1130,1235p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/policy.HC | sed -n '1,120p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/book_of_truth_bridge.HC | sed -n '1,260p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/security_perf_matrix.HC | sed -n '400,520p;610,760p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/attestation_manifest.HC | sed -n '1,40p;220,320p'
```
