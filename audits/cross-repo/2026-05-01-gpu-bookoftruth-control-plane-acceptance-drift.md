# Cross-Repo GPU Book-of-Truth Control-Plane Acceptance Drift

Audit timestamp: 2026-05-01T21:39:16+02:00

Audit angle: cross-repo invariant check. This pass compared the current TempleOS control-plane Book-of-Truth and GPU isolation surfaces against holyc-inference's worker-plane GPU Book-of-Truth assumptions. It did not inspect live loop liveness, restart processes, run QEMU/VM commands, execute WS8 networking tasks, or modify TempleOS / holyc-inference source code. The TempleOS guest air-gap was not touched.

Evidence snapshots:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `9f3abbf26398`.
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `2799283c9554`.
- Sanhedrin audit repo: `/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55` on `codex/sanhedrin-gpt55-audit`.

## Invariant Under Audit

TempleOS `secure-local` is the trust/control plane and the Book of Truth is the source of truth. holyc-inference is the worker plane. GPU acceleration may count toward trusted local inference only if the worker-plane GPU evidence can be accepted by TempleOS without weakening:

- Law 3: Book of Truth immutability.
- Law 8: synchronous, hardware-proximate logging.
- Law 9: crash on log failure.
- Law 10: immutable installed image posture.
- Law 11: local-only Book-of-Truth access.

## Summary

TempleOS has current GPU isolation primitives (`Kernel/IOMMU.HC`) and holyc-inference has a HolyC GPU-to-Book-of-Truth bridge, policy digest, and GPU policy gates. The drift is that the worker plane now has named GPU audit event classes and "hooks enabled" policy bits before the TempleOS Book-of-Truth schema exposes a first-class GPU event/source ABI or fail-stop acceptance path for those classes.

This is not a direct Law 1, Law 2, or Law 4 source violation: both sides are HolyC in core paths, no networking was introduced by this audit, and this pass did not execute any VM. It is a release-readiness warning: a future secure-local GPU enablement could look complete in holyc-inference while still being non-acceptable to the TempleOS control plane.

Finding count: 5 warnings, 0 critical findings.

## Findings

### WARNING-001: holyc-inference defines GPU Book-of-Truth event classes that TempleOS does not yet expose as a Book-of-Truth schema ABI

Evidence:
- TempleOS Book-of-Truth events are currently `BOT_EVENT_INIT` through `BOT_EVENT_SERIAL_WATCHDOG` with numeric IDs 1-20 in `Kernel/BookOfTruth.HC:3-22`.
- TempleOS sources are currently `BOT_SOURCE_KERNEL`, `CLI`, `IRQ`, `MSR`, `EXCEPTION`, `IO`, and `DISK` in `Kernel/BookOfTruth.HC:141-148`.
- holyc-inference defines worker-plane GPU event classes `BOT_GPU_EVENT_DMA`, `BOT_GPU_EVENT_MMIO`, and `BOT_GPU_EVENT_DISPATCH` in `src/gpu/book_of_truth_bridge.HC:22-24`.
- A TempleOS search for `BOT_EVENT_GPU` / `BOT_GPU` in the Book-of-Truth schema surfaces found no first-class GPU event/source constants; current GPU hits are in the IOMMU manager and task ledger, not the Book-of-Truth event ABI.

Impact: cross-repo consumers cannot prove that worker-plane GPU events map to immutable TempleOS ledger records rather than to an inference-local ring format. This weakens Law 8 and Law 11 acceptance for GPU telemetry.

### WARNING-002: The inference GPU bridge overwrites oldest events when full, while TempleOS Book-of-Truth doctrine requires the log to win or halt

Evidence:
- holyc-inference `BOTGPUBridgeAppendChecked` writes to `bridge->head`, advances modulo capacity, and explicitly documents "overwriting the oldest event when full" in `src/gpu/book_of_truth_bridge.HC:140-161`.
- TempleOS Law 9 requires the OS to die before the log dies. The control-plane implementation has a serial write failure halt path in `Kernel/BookOfTruthSerialCore.HC:37-50`, and strict fail-stop clamping in `Kernel/BookOfTruthSerialCore.HC:52-82`.

Impact: overwriting the oldest worker-plane GPU audit event can be a valid bounded telemetry cache, but it cannot be accepted as the Book of Truth itself. The contract needs an explicit "staging buffer only" boundary or a fail-stop transfer rule before secure-local GPU use.

### WARNING-003: Inference policy bits can say Book-of-Truth GPU hooks are enabled before TempleOS has completed the matching GPU Book-of-Truth tasks

Evidence:
- holyc-inference policy digest defaults `g_policy_bot_dma_log_enabled`, `g_policy_bot_mmio_log_enabled`, and `g_policy_bot_dispatch_log_enabled` to `1` in `src/runtime/policy_digest.HC:27-33`.
- holyc-inference GPU policy says dispatch is denied unless IOMMU and Book-of-Truth DMA/MMIO/dispatch hooks are all active in `src/gpu/policy.HC:4-8`, and enforces the three hook bits before allowing command submission in `src/gpu/policy.HC:82-90`.
- TempleOS marks GPU IOMMU and MMIO allowlist tasks done (`WS14-10`, `WS14-11`) but leaves `WS14-12` Book-of-Truth DMA lease events, `WS14-14` dispatch transcript capture, and `WS14-16` fail-closed boot gate open in `MODERNIZATION/MASTER_TASKS.md:267-275`.

Impact: the worker plane can report a secure-looking policy tuple before the control plane has a complete corresponding acceptance surface. That makes policy digest parity insufficient as a release gate by itself.

### WARNING-004: TempleOS records generic DMA payloads as `BOT_EVENT_NOTE`, not as a GPU-specific DMA event family

Evidence:
- TempleOS defines `BOT_DMA_PAYLOAD_MARKER` and DMA op constants in `Kernel/BookOfTruth.HC:41-72`.
- `BookTruthDMARecord` encodes DMA payloads and appends them as `BOT_EVENT_NOTE` with caller-selected source, not as a distinct DMA event type, in `Kernel/BookOfTruth.HC:82493-82522`.
- holyc-inference's bridge has a dedicated `BOT_GPU_EVENT_DMA` type and DMA map/update/unmap ops in `src/gpu/book_of_truth_bridge.HC:22-28`.

Impact: an offline auditor cannot distinguish GPU DMA lifecycle events from other NOTE payloads without out-of-band payload-marker parsing. This is acceptable for internal diagnostics, but weak for Law 8 hardware-proximity and Law 9 fail-stop claims tied specifically to GPU DMA.

### WARNING-005: The cross-repo control-plane/worker-plane rule exists in policy text, but the current source surfaces do not yet give Sanhedrin a crisp acceptance predicate

Evidence:
- TempleOS policy says secure-local keeps TempleOS as trust/control plane and requires attestation evidence plus policy digest match from the worker plane in `MODERNIZATION/MASTER_TASKS.md:41-47`.
- TempleOS policy also says any GPU enablement task must have matching enforcement tasks in holyc-inference and matching critical Sanhedrin checks in `MODERNIZATION/MASTER_TASKS.md:49-54`.
- holyc-inference mission text says every token must be logged to the Book of Truth and GPU acceleration is forbidden unless IOMMU plus Book-of-Truth telemetry are active in `MASTER_TASKS.md:9-29`.
- The current inspected surfaces expose partial pieces: TempleOS IOMMU/MMIO primitives, worker-plane GPU bridge events, and worker-plane policy digest bits, but no single committed contract that says which TempleOS event/source IDs and fail-stop outcomes make a GPU worker run acceptable.

Impact: Sanhedrin can flag obvious missing pieces, but cannot yet compute a binary "secure-local GPU worker evidence accepted by TempleOS Book of Truth" result from the repos alone. That creates a future release-gate ambiguity rather than a current critical breach.

## Recommended Backlog Outcome

Create a blocking cross-repo contract before any secure-local GPU enablement is accepted:

- TempleOS Book-of-Truth ABI: first-class GPU event/source or documented payload-marker mapping for DMA/MMIO/dispatch.
- Worker-plane bridge status: explicitly "staging only" until synchronously appended into TempleOS Book of Truth.
- Fail-stop rule: bridge overflow, transfer failure, serial failure, or control-plane rejection must force CPU-only safe fallback or halt according to profile.
- Sanhedrin predicate: a named check that joins TempleOS ABI version, holyc-inference policy digest bits, and open WS14/WS9 task state.
