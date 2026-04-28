# Cross-Repo GPU Book-of-Truth Bridge Drift Audit

Timestamp: `2026-04-28T10:54:55+02:00`

Audit angle: cross-repo invariant check between TempleOS Book-of-Truth control-plane semantics and holyc-inference GPU audit bridge / policy assumptions.

Repositories audited:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `e868ba65878b282ff5b2d2464b6bd95cb56e6c76`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `ce09228422dae06e86feb84925d51df88d67821b`
- Sanhedrin audit repo: `/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55` at `69e9d332855ca5693338dd096161a70d9ec7174a`

Safety posture: read-only against TempleOS and holyc-inference. No QEMU or VM command was executed. No networking task was executed or recommended.

## Scope

This audit checked whether GPU audit events assumed by `holyc-inference` can be consumed as true Book-of-Truth evidence by TempleOS under LAWS.md:
- Law 2, Air-Gap Sanctity
- Law 3, Book of Truth Immutability
- Law 8, Book of Truth Immediacy & Hardware Proximity
- Law 9, Resource Supremacy / Crash on Log Failure
- Law 11, Book of Truth Local Access Only

Primary evidence reviewed:
- TempleOS `Kernel/BookOfTruth.HC`
- TempleOS `Kernel/BookOfTruthSerialCore.HC`
- TempleOS `MODERNIZATION/MASTER_TASKS.md`
- TempleOS `MODERNIZATION/LOOP_PROMPT.md`
- holyc-inference `automation/check-trinity-policy-sync.sh`
- holyc-inference `src/gpu/book_of_truth_bridge.HC`
- holyc-inference `src/gpu/policy.HC`
- holyc-inference `src/runtime/policy_digest.HC`
- holyc-inference `MASTER_TASKS.md`
- Sanhedrin `LOOP_PROMPT.md`

## Summary

The existing trinity policy signature gate passes: 21 checks passed, 0 failed. The docs agree that GPU dispatch requires IOMMU and Book-of-Truth DMA/MMIO/dispatch hooks.

The drift is below the doc layer. `holyc-inference` defines a GPU "Book-of-Truth bridge" as an in-memory ring supplied by the caller, while TempleOS `BookOfTruth.HC` has no GPU event/source IDs and clamps all known events to `BOT_EVENT_SERIAL_WATCHDOG` and all sources to `BOT_SOURCE_DISK`. The inference worker can therefore assert local GPU hook booleans and emit local bridge records that are not yet a TempleOS Book-of-Truth event stream.

This audit found no evidence of guest networking, VM networking, socket/TCP/IP/TLS/DHCP/DNS/HTTP work, or WS8 networking execution. The findings are warnings because the reviewed code is policy/gating infrastructure, not evidence that GPU dispatch is currently enabled in a trusted run.

## Findings

### Finding WARNING-001: holyc-inference defines GPU Book-of-Truth event IDs that TempleOS cannot ingest

Evidence:
- `holyc-inference/src/gpu/book_of_truth_bridge.HC:22-34` defines `BOT_GPU_EVENT_DMA`, `BOT_GPU_EVENT_MMIO`, `BOT_GPU_EVENT_DISPATCH`, and GPU op IDs.
- `TempleOS/Kernel/BookOfTruth.HC:3-22` defines Book-of-Truth event IDs only through `BOT_EVENT_SERIAL_WATCHDOG`.
- `TempleOS/Kernel/BookOfTruth.HC:79-86` defines sources only through `BOT_SOURCE_DISK`.
- `TempleOS/Kernel/BookOfTruth.HC:1432-1433` and `1506-1509` clamp out-of-range event/source values back into the existing range.

Impact:

GPU DMA/MMIO/dispatch evidence produced by the inference bridge has no canonical TempleOS event/source namespace. If a future integration maps these records through the current TempleOS ledger without adding explicit GPU events, they will be rejected, clamped, or misclassified instead of appearing as auditable GPU activity.

Recommendation:

Reserve TempleOS Book-of-Truth constants for GPU DMA map/update/unmap, MMIO write, dispatch submit/complete/timeout, and a GPU source. Treat missing GPU event IDs as a release blocker for any GPU dispatch path.

### Finding WARNING-002: the inference GPU bridge uses overwriteable ring-buffer semantics, not Book-of-Truth immediacy semantics

Evidence:
- `holyc-inference/src/gpu/book_of_truth_bridge.HC:47-54` stores bridge events in caller-supplied memory with `capacity`, `count`, and `head`.
- `holyc-inference/src/gpu/book_of_truth_bridge.HC:154-163` advances modulo capacity and explicitly overwrites the oldest event when full.
- LAWS.md Law 8 forbids log queues or ring buffers that decouple the event from serial `out 0x3F8`.
- TempleOS `BookOfTruth.HC:88-95` anchors serial output at COM1 `0x3F8`.

Impact:

The bridge is useful as a local worker transcript, but it is not equivalent to the Book of Truth. Calling it "Book-of-Truth" risks confusing overwriteable worker-plane telemetry with the immutable, synchronous, serial-exfiltrated control-plane ledger required by Laws 3, 8, and 9.

Recommendation:

Rename or document the bridge as a worker-plane staging transcript until TempleOS has an inline GPU BookTruth append path that serializes each GPU event synchronously. Any trusted GPU dispatch should require TempleOS-side serial evidence, not only worker bridge entries.

### Finding WARNING-003: GPU dispatch policy trusts caller-supplied hook booleans without TempleOS attestation binding

Evidence:
- `holyc-inference/src/gpu/policy.HC:34-40` accepts `iommu_enabled`, `bot_dma_log_enabled`, `bot_mmio_log_enabled`, and `bot_dispatch_log_enabled` as inputs.
- `holyc-inference/src/gpu/policy.HC:76-90` allows dispatch if these booleans satisfy the gate.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:268-279` still lists kernel IOMMU manager, GPU BAR/MMIO allowlist, DMA lease events, attestation verifier, and policy-digest handshake as unchecked future tasks.

Impact:

The inference worker has a fail-closed local policy function, but TempleOS does not yet provide the authoritative proof that the booleans are true. Without an attestation-bound control-plane source, a future integration could pass synthetic `1` values and satisfy the worker gate without actual IOMMU or Book-of-Truth hooks.

Recommendation:

Bind `iommu_enabled` and each Book-of-Truth hook bit to TempleOS-generated attestation evidence and policy digest input. The worker should accept these flags only from the control plane, not from arbitrary local call sites.

### Finding WARNING-004: runtime policy digest defaults report all GPU guard bits enabled before TempleOS support exists

Evidence:
- `holyc-inference/src/runtime/policy_digest.HC:27-33` initializes `g_policy_iommu_enabled`, `g_policy_bot_dma_log_enabled`, `g_policy_bot_mmio_log_enabled`, and `g_policy_bot_dispatch_log_enabled` to `1`.
- `holyc-inference/src/runtime/policy_digest.HC:135-147` publishes those bits into the policy bitfield.
- TempleOS source search found IOMMU/GPU support only in policy docs and future task rows, not in `Kernel/` implementation.

Impact:

The worker policy digest can claim a fully enabled GPU security posture by default even though TempleOS has not implemented the matching kernel control-plane evidence. This creates cross-repo drift between what holyc-inference can attest locally and what TempleOS can actually enforce today.

Recommendation:

Default GPU guard bits to disabled unless supplied by a TempleOS attestation bundle. A digest with GPU bits enabled should be invalid unless TempleOS can verify IOMMU mode, Book-of-Truth event IDs, and serial ledger emission.

### Finding WARNING-005: Trinity policy gate checks documentation signatures, not source-level GPU ledger compatibility

Evidence:
- `holyc-inference/automation/check-trinity-policy-sync.sh` passed 21/21 checks against this worktree's Sanhedrin `LOOP_PROMPT.md`.
- The gate checks doc regexes for secure-local, dev-local, quarantine/hash, GPU/IOMMU/Book-of-Truth, attestation/policy digest, and drift guard language.
- The gate does not compare TempleOS `BOT_EVENT_*` / `BOT_SOURCE_*` constants against `holyc-inference/src/gpu/book_of_truth_bridge.HC` event/op constants.

Impact:

The trinity can look synchronized at the policy-doc level while source-level ABI drift accumulates. This is specifically risky for Law 8 because GPU "hooks active" is meaningful only if the hook emits into the same synchronous ledger schema that TempleOS enforces.

Recommendation:

Add a read-only source-level cross-repo check that fails when inference introduces `BOT_GPU_*` event/op constants without matching TempleOS Book-of-Truth event/source definitions and serial append semantics.

## Positive Observations

- `GPUPolicyAllowDispatchChecked` fails closed when IOMMU or Book-of-Truth hook flags are absent.
- The GPU bridge and policy code are HolyC and use integer-only data structures.
- TempleOS and holyc-inference docs agree that GPU dispatch is forbidden unless IOMMU and Book-of-Truth hooks are active.
- Existing trinity policy signature gate passed with 21 checks and 0 failures.

## Safety Notes

- No TempleOS guest networking stack, NIC driver, socket, TCP/IP, UDP, TLS, DHCP, DNS, HTTP, or remote runtime service was added or enabled.
- No WS8 networking task was executed or recommended.
- No QEMU or VM command was executed during this audit.
- Recommendations preserve the air-gap and keep core TempleOS/inference implementation in HolyC.

## Commands Run

Read-only commands only:

```bash
sed -n '1,240p' LAWS.md
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS status --short --branch
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS log --oneline --decorate -n 12
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference status --short --branch
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference log --oneline --decorate -n 12
TRINITY_SANHEDRIN_DOC=/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55/LOOP_PROMPT.md bash automation/check-trinity-policy-sync.sh
rg -n "IOMMU|VT-d|AMD-Vi|GPU|DMA|BookTruth.*GPU|BOT_.*GPU|BookTruth.*Inference|Inference.*BookTruth|policy.*digest|attestation|quarantine|secure-local|dev-local" Kernel Adam Compiler Apps MODERNIZATION -S
rg -n "BOT_|BOOK|BookTruth|GPU|DMA|IOMMU|POLICY|PROFILE|SECURE|DEV|QUARANTINE|ATTEST" src -S
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/book_of_truth_bridge.HC | sed -n '1,210p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/policy.HC | sed -n '1,150p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/policy_digest.HC | sed -n '1,220p'
rg -n "BOT_SOURCE_|BOT_EVENT_|BookTruthAppend\\(|BookTruthSerialEmit|OutU8|0x3F8|COM1" Kernel/BookOfTruth.HC Kernel/BookOfTruthSerialCore.HC Kernel/KernelA.HH Kernel/KExts.HC -S
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC | sed -n '1,120p;560,700p'
rg -n "BOT_GPU|BOT_SOURCE_GPU|BOT_EVENT_GPU|GPU.*BookTruth|BookTruth.*GPU|IOMMU|VT-d|AMD-Vi|DMAR" Kernel MODERNIZATION -S
rg -n "BOT_GPU|BOT_SOURCE_GPU|BOT_EVENT_GPU|GPU.*BookTruth|BookTruth.*GPU|IOMMU|VT-d|AMD-Vi|DMAR" src MASTER_TASKS.md LOOP_PROMPT.md -S
git rev-parse HEAD
```

Finding count: 5 warnings, 0 critical violations.
