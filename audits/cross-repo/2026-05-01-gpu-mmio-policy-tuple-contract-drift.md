# Cross-Repo Audit: GPU MMIO Policy Tuple Contract Drift

Timestamp: 2026-05-01T13:39:10+02:00

Scope:
- TempleOS repo: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS`
- TempleOS head: `9f3abbf263982bf9344f8973a52f845f1f48d109`
- holyc-inference repo: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference`
- holyc-inference head: `2799283c9554bea44c132137c590f02034c8f726`
- Audit angle: cross-repo invariant check for GPU BAR/MMIO policy and Book-of-Truth event semantics

Read-only/static audit only. No TempleOS or holyc-inference source files were modified. No QEMU, VM, WS8 networking task, socket, TCP/IP, UDP, DNS, DHCP, HTTP, TLS, package install, or remote fetch command was executed.

## Summary

holyc-inference treats GPU MMIO safety as a tuple contract: BAR index, register range, write width, value, and a first-class MMIO Book-of-Truth event. TempleOS current head now has a deny-by-default MMIO allowlist, but the producer-side policy records only exact `(dev, bar, reg)` entries, forces every write to width `8`, compresses BAR/register into two 8-bit fields inside a generic DMA record, and does not log allowlist mutations. That creates a Trinity drift risk: inference can claim secure-local GPU dispatch based on MMIO hooks that TempleOS cannot yet prove with equivalent evidence.

Findings: 5 warnings, 0 critical.

## Findings

### WARNING-1: MMIO allowlist tuple shape differs across repos

Applicable laws:
- Law 5: North Star Discipline
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- TempleOS `Kernel/IOMMU.HC:15-21` defines `CIOMMUGPUMMIO` with only `dev`, `bar`, `reg`, and `live`.
- TempleOS `Kernel/IOMMU.HC:203-232` allows or removes exact `(dev, bar, reg)` entries with no width or register-range fields.
- holyc-inference `src/gpu/mmio_allowlist.HC:28-34` defines `GPUMMIOAllowEntry` as `bar_index`, `reg_start`, `reg_end`, and `width_mask`.
- holyc-inference `src/gpu/mmio_allowlist.HC:126-205` checks range and width before allowing a write.

Assessment:
The inference runtime assumes an allowlist row can express a register window and allowed write widths. TempleOS currently exposes only exact register identity and no width mask, so a secure-local policy digest in inference cannot be mapped losslessly back to the OS-side enforcement surface. This is drift, not an immediate runtime violation, because the current TempleOS path still denies unknown exact registers by default.

Remediation:
- Extend the TempleOS MMIO rule table to include `reg_start`, `reg_end`, and `width_mask`, or add a documented adapter proving exact-register rules are the canonical subset.
- Add a cross-repo fixture that feeds the same BAR/range/width cases into both policy models.

### WARNING-2: TempleOS logs MMIO writes through generic DMA records

Applicable laws:
- Law 8: Book of Truth Immediacy & Hardware Proximity
- Law 3: Book of Truth Immutability

Evidence:
- TempleOS `Kernel/IOMMU.HC:247-270` records MMIO outcomes with `BookTruthDMARecord(BOT_DMA_OP_WRITE, chan, 8, dev, ...)`.
- TempleOS `Kernel/BookOfTruth.HC:70-72` defines DMA operation classes as read/write/bidir, with no separate MMIO operation.
- holyc-inference `src/gpu/book_of_truth_bridge.HC:22-24` defines first-class event types for DMA, MMIO, and dispatch.
- holyc-inference `src/gpu/book_of_truth_bridge.HC:184-199` records MMIO writes as `BOT_GPU_EVENT_MMIO` with `bar_index`, `reg_offset`, `value`, and `width_bytes`.

Assessment:
The consumer-side bridge expects MMIO to be distinguishable from DMA in the ledger. TempleOS currently emits MMIO as a DMA write, so downstream replay cannot tell whether a record represents device memory transfer or register control-plane mutation without extra out-of-band interpretation.

Remediation:
- Add a TempleOS Book-of-Truth MMIO event marker/op, or define a stable DMA-payload subtype that decodes unambiguously as MMIO.
- Require the smoke gate to prove MMIO replay can separate DMA lifecycle records from MMIO register writes.

### WARNING-3: BAR/register payload truncates high bits

Applicable laws:
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- TempleOS `Kernel/IOMMU.HC:247`, `Kernel/IOMMU.HC:258`, and `Kernel/IOMMU.HC:268` compute `chan=((bar&0xFF)<<8)|(reg&0xFF)`.
- TempleOS status strings at `Kernel/IOMMU.HC:250-271` print full `bar`, `reg`, and `value`, but the durable Book-of-Truth payload receives only the compressed `chan` plus fixed bytes.
- holyc-inference `src/gpu/book_of_truth_bridge.HC:184-199` preserves BAR, register offset, value, and width as separate fields.

Assessment:
High BAR/register bits are lost in the durable TempleOS ledger path. The console status line is not an immutable Book-of-Truth record, so it cannot satisfy the inference-side assumption that MMIO evidence contains the full register tuple.

Remediation:
- Preserve full BAR and register offset in the Book-of-Truth payload, either by adding a native MMIO encoder or by writing a multi-field payload sequence with a documented replay decoder.
- Treat the formatted status line as diagnostic only, not audit evidence.

### WARNING-4: MMIO policy transitions are not ledgered

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- TempleOS `Kernel/IOMMU.HC:203-232` mutates `iommu_gpu_mmio` entries but does not call `BookTruthDMARecord` or another Book-of-Truth append routine.
- holyc-inference `src/runtime/policy_digest.HC:135-170` emits a digest over active policy guard bits for audit comparison.
- holyc-inference `src/gpu/policy.HC:82-90` denies dispatch unless DMA, MMIO, and dispatch hooks are all active.

Assessment:
TempleOS can record later MMIO write outcomes, but the policy transition that makes a register trusted is not recorded. That leaves a gap between inference's policy-digest model and TempleOS evidence: a dispatch can be "MMIO hooks active" while the allowlist contents and changes remain unaudited.

Remediation:
- Emit synchronous Book-of-Truth policy events for add, duplicate, remove, missing-remove, and capacity-denied outcomes in `IOMMUGPUMMIOAllow`.
- Include old/new rule counts and the full tuple in the event payload.

### WARNING-5: Smoke gates do not enforce the cross-repo tuple contract

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- TempleOS `automation/iommu-mmio-smoke.sh:12-35` checks for symbols and one blocked-write logging call by grep.
- holyc-inference `tests/test_gpu_mmio_allowlist.py:160-206` validates range, width, bad-table, overlap, and deny-default cases against its own Python mirror.
- No current checked file joins TempleOS `IOMMUGPUMMIOWrite` payload semantics with holyc-inference `BOTGPUBridgeRecordMMIOWrite` or `GPUMMIOAllowlistCheckWriteChecked`.

Assessment:
Both repos have useful local tests, but neither proves that the TempleOS producer ledger can satisfy the inference consumer's MMIO tuple and replay assumptions. This makes future secure-local GPU performance claims hard to verify across Trinity boundaries.

Remediation:
- Add a host-side cross-repo parity fixture in Sanhedrin or shared automation that compares canonical MMIO cases across both repos.
- Include at least: unknown BAR, out-of-range register, width mismatch, allowed register, high-bit register offset, and allowlist mutation evidence.

## Non-Findings

- No networking source, WS8 execution, or QEMU/VM command was used during this audit.
- No non-HolyC implementation was introduced into TempleOS or holyc-inference source by this audit.
- TempleOS current head remains deny-by-default for unknown MMIO writes at the static source level.
- holyc-inference current head remains integer-only in the audited GPU policy and Book-of-Truth bridge files.

## Verification Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
rg -n "IOMMUGPUMMIO|BookTruthDMARecord|BOT_DMA_OP_WRITE|IOMMU_GPU_MMIO_MAX" Kernel MODERNIZATION automation
rg -n "GPUMMIOAllowEntry|GPUMMIOAllowlistCheckWriteChecked|BOT_GPU_EVENT_MMIO|BOTGPUBridgeRecordMMIOWrite|bot_mmio_log_enabled|policy_bits" src tests MASTER_TASKS.md
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/IOMMU.HC | sed -n '1,330p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/mmio_allowlist.HC | sed -n '1,260p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/book_of_truth_bridge.HC | sed -n '1,260p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/policy_digest.HC | sed -n '1,220p'
```
