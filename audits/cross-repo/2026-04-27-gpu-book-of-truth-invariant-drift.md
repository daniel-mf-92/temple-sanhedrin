# Cross-Repo Invariant Audit: GPU Book-of-Truth Drift

Timestamp: 2026-04-27T13:20:02Z

Auditor: gpt-5.5 sibling, retroactive/deep audit scope

Repos examined:
- TempleOS: `96a63ca3f0978c8381e2d251acbf12b73bf4de6f`
- holyc-inference: `5906d630f62d46da2d916e8d0fe2b27460f41dfb`
- temple-sanhedrin: `90c3d8949d13cc5dbbd4ccc777deb94d6fb641ba`

Audit angle: cross-repo invariant check. No trinity source code was modified.

## Executive Summary

Found 1 release-blocking invariant drift.

The drift is not a live liveness issue. It is a historical/cross-repo contract mismatch between TempleOS/LAWS Book-of-Truth semantics and holyc-inference GPU audit helpers.

## Finding CRITICAL-001: Inference GPU audit helpers can satisfy "Book-of-Truth hooks active" with bounded in-memory ring/transcript semantics

Severity: CRITICAL

Laws implicated:
- Law 3: Book of Truth immutability
- Law 8: Book of Truth immediacy and hardware proximity
- Law 9: crash on log failure / resource supremacy

TempleOS/LAWS contract:
- `LAWS.md:37-45` forbids any Book-of-Truth path that can overwrite sealed log pages, remove serial exfiltration, add disable knobs, or make hash-chain behavior skippable.
- `LAWS.md:96-109` explicitly treats a log queue/ring buffer that decouples the event from serial `out 0x3F8` as a violation.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:159-175` requires each act to exit immediately through `out 0x3F8`, synchronously, with no callback, deferred write, batching, async queue, or delayed flush.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:187-188` begins the resource supremacy rule: the OS dies before the log dies.

holyc-inference assumption:
- `src/gpu/policy.HC:34-90` allows GPU dispatch when `iommu_enabled`, `bot_dma_log_enabled`, `bot_mmio_log_enabled`, and `bot_dispatch_log_enabled` are binary true. It does not distinguish hard Book-of-Truth UART/HLT semantics from softer local telemetry flags.
- `src/gpu/book_of_truth_bridge.HC:47-53` models the bridge as caller-provided event storage with `capacity`, `count`, `head`, and `next_seq_id`.
- `src/gpu/book_of_truth_bridge.HC:140-155` writes the event into `events[head]` and explicitly wraps modulo capacity, "overwriting the oldest event when full."
- `src/gpu/dispatch_transcript.HC:44-52` similarly models dispatch evidence as bounded storage with `capacity`, `count`, `head`, and `next_seq_id`.
- `src/gpu/dispatch_transcript.HC:290-319` commits entries into `entries[head]`, advances `head`, and wraps at capacity.
- `src/gpu/dispatch_transcript.HC:4-8` describes the transcript as "Designed for Book-of-Truth export and offline replay verification," which is export/replay semantics rather than synchronous Book-of-Truth write-path semantics.

Why this is drift:
- TempleOS treats Book-of-Truth GPU logging as a hardware-proximate, synchronous serial fact, not a bounded in-memory staging structure.
- holyc-inference currently has helpers that can be read as Book-of-Truth telemetry while still dropping old entries under capacity pressure.
- `GPUPolicyAllowDispatchChecked` can accept boolean "hooks enabled" without proving that those hooks are the TempleOS WS13 path: raw UART `out 0x3F8`, no buffering/queue decoupling, no oldest-entry overwrite, and halt/fail-closed behavior on log inability.

Impact:
- A future integration could enable GPU dispatch by wiring the policy booleans to the existing bridge/transcript helpers, incorrectly satisfying the inference-side guard while violating TempleOS Book-of-Truth semantics.
- This would weaken the `secure-local` control-plane contract because GPU DMA/MMIO/dispatch evidence could be overwritten or merely exported later.

Recommended remediation:
- Treat `book_of_truth_bridge.HC` and `dispatch_transcript.HC` as non-authoritative preflight/diagnostic mirrors unless every successful append is coupled to the TempleOS WS13 synchronous serial write path.
- Rename or document these structures as "telemetry mirror" or "preflight transcript" until they are backed by hard Book-of-Truth writes.
- Extend the GPU policy gate beyond booleans: require an attested Book-of-Truth writer mode that proves synchronous UART emission, non-overwrite behavior, and fail-stop behavior.
- Add paired tasks in TempleOS and holyc-inference to define the exact ABI between GPU event production and WS13 logging.

## Healthy Parity Observations

- Air-gap policy is aligned across the trinity docs: TempleOS requires `secure-local`/`dev-local` profiles to remain air-gapped, holyc-inference states models are disk-only with no HTTP/networking, and sanhedrin `LOOP_PROMPT.md` has CRITICAL GPU/profile parity checks.
- HolyC purity scan of core paths found no foreign-language implementation files in TempleOS core directories or `holyc-inference/src`.
- No QEMU or VM command was executed during this audit.

## Verification Commands

Read-only commands used:
- `rg -n "Book|Truth|UART|0x3F8|serial|HLT|halt|air|network|QEMU|qemu|-nic|-net|readonly|WS8|WS13|GPU|DMA|MMIO|remote|local" ...`
- `find ... -type f \( -name '*.c' -o -name '*.cpp' -o -name '*.rs' -o -name '*.go' -o -name '*.py' -o -name '*.js' -o -name '*.ts' -o -name 'Makefile' -o -name 'CMakeLists.txt' -o -name 'Cargo.toml' \)`
- `nl -ba` on cited TempleOS, holyc-inference, and sanhedrin files.
