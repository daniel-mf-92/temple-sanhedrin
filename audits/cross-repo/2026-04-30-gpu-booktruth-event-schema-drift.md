# Cross-Repo Audit: GPU Book-of-Truth Event Schema Drift

Timestamp: 2026-04-30T07:46:55+02:00

Audit angle: cross-repo invariant check for whether holyc-inference GPU audit rows match the TempleOS Book-of-Truth append surface and current secure-local policy gates.

Repos reviewed:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `5cad1338f17141988b9c85d360e4a87608cebea7` on `codex/modernization-loop`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `2799283c9554bea44c132137c590f02034c8f726` on `main`
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit`

No TempleOS or holyc-inference source file was modified. No QEMU, VM, WS8 networking, package-download, or data-modifying command was executed.

## Expected Cross-Repo Invariant

If holyc-inference claims GPU dispatch is protected by Book-of-Truth hooks, every worker-side DMA/MMIO/dispatch row must be joinable to a TempleOS Book-of-Truth append ABI with matching event class, payload fields, sequence/hash evidence, and local-only access semantics. Worker telemetry can describe intended events, but it cannot substitute for TempleOS append proof.

Finding count: 4 findings: 4 warnings.

## Findings

### WARNING-001: holyc-inference defines three GPU event classes, but TempleOS exposes only DMA and generic I/O-port append surfaces

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy & Hardware Proximity
- Law 11: Book of Truth Local Access Only

Evidence:
- holyc-inference `src/gpu/book_of_truth_bridge.HC` defines `BOT_GPU_EVENT_DMA`, `BOT_GPU_EVENT_MMIO`, and `BOT_GPU_EVENT_DISPATCH`, then accepts separate record helpers for DMA, MMIO write, and dispatch events (`lines 22-34`, `166-217`).
- TempleOS exports `BookTruthDMARecord`, `BookTruthIOPortStatus`, `BookTruthIOPortAllowlistStatus`, `BookTruthInU8Log`, and `BookTruthOutU8Log`, but no `BookTruthGPU*`, `BookTruthMMIO*`, or `BookTruthDispatch*` ABI in the reviewed export surface (`Kernel/KExts.HC:126-135`).
- TempleOS policy still lists GPU BAR/MMIO allowlist, DMA lease model, dispatch transcript, fail-closed GPU boot gate, control-plane contract, attestation verifier, and policy-digest handshake as open WS14 work (`MODERNIZATION/MASTER_TASKS.md:267-278`).

Assessment:
The worker plane has a richer event taxonomy than the TempleOS trust plane currently exposes. Treating `bot_mmio_log_enabled` or `bot_dispatch_log_enabled` as real TempleOS evidence would be premature until TempleOS has explicit MMIO/dispatch Book-of-Truth append records or a documented mapping from those worker classes into current TempleOS payloads.

Required remediation:
- Define a TempleOS `BookTruthGPU*` ABI or a normative mapping from worker DMA/MMIO/dispatch classes to existing TempleOS events.
- Until that exists, require reports to label worker GPU bridge output as preflight telemetry, not Book-of-Truth proof.

### WARNING-002: DMA payload schemas do not match across repos

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- TempleOS DMA payloads encode `op`, `chan`, `bytes`, `dev`, `iommu`, and `blocked` into a compact `BOT_DMA_PAYLOAD_MARKER` word (`Kernel/BookOfTruth.HC:81538-81568`), then append that payload through `BookTruthAppend(BOT_EVENT_NOTE, source, payload)` (`Kernel/BookOfTruth.HC:81605-81632`).
- holyc-inference DMA bridge rows store `dma_op`, `lease_id`, `phys_addr`, `nbytes`, and `iommu_domain` into a worker-local event tuple (`src/gpu/book_of_truth_bridge.HC:166-181`).
- The shared policies require GPU work to enforce IOMMU plus Book-of-Truth DMA/MMIO logging before dispatch (`TempleOS/MODERNIZATION/LOOP_PROMPT.md:64-66`; `holyc-inference/LOOP_PROMPT.md:21-29`, `64-70`).

Assessment:
Both sides use integer-only HolyC-compatible fields, but the semantics are not joinable without a translation contract. A worker `lease_id`/`phys_addr`/`iommu_domain` row cannot be decoded by TempleOS `BookTruthDMAPayloadDecode`, and a TempleOS `chan`/`dev`/`blocked` payload cannot be replayed by the worker bridge without losing meaning.

Required remediation:
- Add a shared `GPU_DMA_BOT_V1` schema with field names, bit widths, clamping rules, and decode rules.
- Include TempleOS `bot_seq` and payload marker/hash in worker evidence once real append proof exists.

### WARNING-003: Worker bridge ring overwrite semantics conflict with Book-of-Truth immutability if treated as authoritative

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 9: Resource Supremacy / Crash on Log Failure

Evidence:
- holyc-inference bridge storage is caller-supplied and bounded by `capacity` (`src/gpu/book_of_truth_bridge.HC:47-54`, `85-101`).
- `BOTGPUBridgeAppendChecked` advances `head` modulo capacity and explicitly overwrites the oldest event when full (`src/gpu/book_of_truth_bridge.HC:140-161`).
- TempleOS Law 3 forbids clearing, truncating, or overwriting sealed log pages, and Law 9 requires the OS to halt rather than continue after Book-of-Truth write failure.

Assessment:
The worker ring is acceptable as temporary telemetry if named and reported that way. It is not compliant as Book-of-Truth evidence because it permits loss of older security events under capacity pressure and returns success after overwrite.

Required remediation:
- Rename or document worker bridge rows as non-authoritative until joined to TempleOS append proof.
- For any future authoritative bridge, fail closed on capacity exhaustion and require TempleOS append success before dispatch progresses.

### WARNING-004: "Book-of-Truth export" wording is ambiguous against local-only access policy

Applicable laws:
- Law 11: Book of Truth Local Access Only

Evidence:
- holyc-inference `src/gpu/dispatch_transcript.HC` says the transcript is "Designed for Book-of-Truth export and offline replay verification" (`lines 1-8`).
- Law 11 forbids log export commands and any path that makes log contents available outside the local console.
- The reviewed file implements a local deterministic transcript recorder; this audit did not find an actual remote endpoint or network path in the file.

Assessment:
This is not a current air-gap or remote-access violation. The risk is terminology drift: "export" can be read as a future command to dump Book-of-Truth contents, which would violate Law 11 unless it means local in-memory formatting for on-console inspection or Sanhedrin-local replay of already captured host artifacts.

Required remediation:
- Replace or define "export" in GPU transcript docs as "local-only render/replay input" with no USB, network, remote, or removable-media path.
- Add a Sanhedrin rule that any future Book-of-Truth export helper must prove local-only access and no remote transport.

## Non-Findings

- No guest networking, QEMU, VM, or WS8 networking task was executed during this audit.
- No non-HolyC implementation language was found in the reviewed runtime GPU bridge files.
- TempleOS keeping WS14 GPU trust-plane tasks open is safer than claiming secure-local GPU readiness prematurely.

## Suggested Sanhedrin Follow-Up

Add a cross-repo release evidence rule: `Book-of-Truth GPU hooks active` is false unless a worker event row includes a matching TempleOS append tuple: `bot_seq`, `event_type`, `source`, `payload_marker`, payload fields, entry/hash proof, and local-only replay status.

## Evidence Commands

- `git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD`
- `git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD`
- `git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS branch --show-current`
- `git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference branch --show-current`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/book_of_truth_bridge.HC | sed -n '1,220p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/dispatch_transcript.HC | sed -n '1,220p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/KExts.HC | sed -n '120,136p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC | sed -n '30,75p;2081,2210p;2550,2585p;81538,81633p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '262,279p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/LOOP_PROMPT.md | sed -n '20,31p;64,71p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/LOOP_PROMPT.md | sed -n '38,66p'`
- `rg -n "BookTruth(MMIO|GPU|Dispatch|BAR|IOMMU|DMA)|MMIO|dispatch|BOT_GPU|BOT_DMA|BOT_DMA_OP|BOT_DMA_PAYLOAD_MARKER" /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/*.HC /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/*.md`
