# Cross-Repo Audit: GPU Session Lifecycle Contract Drift

Timestamp: 2026-05-01T16:44:34+02:00

Scope:
- TempleOS repo: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS`
- holyc-inference repo: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference`
- Audit angle: cross-repo invariant check for GPU reset/scrub, dispatch transcript, and Book-of-Truth lifecycle evidence.

Read-only/static audit only. No TempleOS or holyc-inference source files were modified. No QEMU, VM, WS8 networking task, socket, TCP/IP, UDP, DNS, DHCP, HTTP, TLS, package install, remote fetch, or live liveness watch command was executed.

## Summary

holyc-inference has implemented helper-level GPU session primitives for reset/scrub and deterministic dispatch transcripts, but TempleOS current head does not yet expose matching kernel/session lifecycle surfaces. TempleOS still has WS14-13 and WS14-14 open, and its current GPU kernel implementation covers IOMMU DMA windows and MMIO allowlist writes only. This is expected sequencing if GPU work remains guarded, but it is a cross-repo drift risk because inference-side helpers now model session fences and transcripts that TempleOS cannot yet record as first-class Book-of-Truth events.

Findings: 5 warnings, 0 critical.

## Findings

### WARNING-1: Inference reset/scrub helper has no TempleOS lifecycle counterpart yet

Applicable laws:
- Law 5: North Star Discipline
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- `holyc-inference/src/gpu/reset_scrub.HC:1-9` defines a GPU reset + memory scrub sequencing helper whose contract says trusted sessions must be fenced by deterministic pre/post sequences.
- `holyc-inference/src/gpu/reset_scrub.HC:192-269` implements `GPUResetScrubRunPreTrustedSessionChecked`, setting `session_active=1` after planning reset and scrub steps.
- `holyc-inference/src/gpu/reset_scrub.HC:272-349` implements `GPUResetScrubRunPostTrustedSessionChecked`, clearing `session_active` after the post-session sequence.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:271` still leaves WS14-13 unchecked: GPU reset + memory scrub flow before and after model dispatch sessions.
- Current TempleOS GPU kernel search found `IOMMUGPU*` and `IOMMUGPUMMIO*` APIs, but no `GPUResetScrub*`, GPU reset, or GPU memory scrub kernel surface.

Assessment:
Inference can model a trusted GPU session lifecycle, but the OS side cannot yet enforce, execute, or ledger the same pre/post lifecycle. Until TempleOS owns the actual hardware-proximate reset/scrub path, any inference-side "trusted session" remains a local helper contract rather than an end-to-end trinity invariant.

Remediation:
- Add a TempleOS WS14-13 implementation that owns reset/scrub state at the same privilege boundary as IOMMU/MMIO policy.
- Emit Book-of-Truth records for pre-reset, pre-scrub, session-open, post-scrub, post-reset, and failure outcomes.

### WARNING-2: Dispatch transcript exists in inference but lacks a TempleOS capture/verification surface

Applicable laws:
- Law 5: North Star Discipline
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- `holyc-inference/src/gpu/dispatch_transcript.HC:1-8` describes a deterministic GPU dispatch transcript intended for Book-of-Truth export and offline replay verification.
- `holyc-inference/src/gpu/dispatch_transcript.HC:23-42` defines transcript entries with queue depth, descriptor address/size/type/op, cycle window, status, entry hash, and chain hash.
- `holyc-inference/src/gpu/dispatch_transcript.HC:207-260` records dispatch transcript entries with alignment, cycle-window, and state checks.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:272` still leaves WS14-14 unchecked: deterministic GPU dispatch transcript capture.
- Current TempleOS kernel search found no `BOT_GPU_EVENT_DISPATCH`, `GPUDispatchTranscript*`, or first-class GPU dispatch transcript capture surface.

Assessment:
Inference can compute a deterministic transcript, but TempleOS cannot yet capture or validate the OS-side dispatch record that the transcript is supposed to mirror. This weakens parity replay: a model-side transcript may be internally consistent while the kernel Book-of-Truth lacks the corresponding hardware-proximate dispatch entry.

Remediation:
- Define a shared TempleOS/holyc-inference dispatch transcript tuple before enabling trusted GPU dispatch.
- Add TempleOS Book-of-Truth dispatch events with descriptor hash, queue id/depth, timing window, status, and transcript chain hash.

### WARNING-3: Book-of-Truth GPU bridge omits reset/scrub event classes

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- `holyc-inference/src/gpu/book_of_truth_bridge.HC:9-12` says the bridge records DMA lifecycle, MMIO writes, and dispatch submissions.
- `holyc-inference/src/gpu/book_of_truth_bridge.HC:22-24` defines only `BOT_GPU_EVENT_DMA`, `BOT_GPU_EVENT_MMIO`, and `BOT_GPU_EVENT_DISPATCH`.
- `holyc-inference/src/gpu/book_of_truth_bridge.HC:166-217` provides record helpers for DMA, MMIO write, and dispatch, but not reset, scrub, session-open, or session-close events.
- `holyc-inference/src/gpu/reset_scrub.HC:237-267` and `:317-347` update reset/scrub counters and sequence IDs without calling a Book-of-Truth bridge function.

Assessment:
The reset/scrub helper treats session fencing as security-critical, but the bridge cannot represent those fence events. A future replay can see dispatch entries without a canonical pre/post reset-scrub proof in the same event stream. That is a ledger-schema drift risk, not a source-code purity violation.

Remediation:
- Add reset/scrub/session event types to the shared GPU Book-of-Truth event vocabulary.
- Require reset/scrub helper paths to emit ordered bridge records or to return event tuples that TempleOS can append synchronously.

### WARNING-4: Secure gate does not cover the newer reset/scrub and transcript prerequisites

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- `holyc-inference/automation/inference-secure-gate.sh:63-67` checks IOMMU policy, Book-of-Truth DMA/MMIO/dispatch hooks, DMA unmap, command verification, and dispatch policy.
- The same gate does not check `src/gpu/reset_scrub.HC`, `GPUResetScrubRunPreTrustedSessionChecked`, `GPUResetScrubRunPostTrustedSessionChecked`, `src/gpu/dispatch_transcript.HC`, or `GPUDispatchTranscriptRecordChecked`.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:271-272` keeps the matching OS-side reset/scrub and transcript tasks open.

Assessment:
The release gate still reflects the earlier GPU safety baseline. As inference adds session lifecycle artifacts, the gate can pass without proving the reset/scrub and transcript invariants that the newer helpers now assume. That makes cross-repo readiness ambiguous.

Remediation:
- Extend `inference-secure-gate.sh` with WS9-28 and WS9-29 checks, but mark them as blocked on TempleOS WS14-13 and WS14-14 until kernel support lands.
- Add a Sanhedrin cross-repo gate that refuses "trusted GPU session" readiness while either side lacks the lifecycle/transcript half.

### WARNING-5: Task status disagrees between workstream rows and completed IQ artifacts

Applicable laws:
- Law 5: North Star Discipline
- Law 6: Queue Health

Evidence:
- `holyc-inference/MASTER_TASKS.md:152-153` still leaves WS9-28 and WS9-29 unchecked.
- `holyc-inference/MASTER_TASKS.md:1155-1156` marks IQ-1262 and IQ-1263 complete for those same workstreams.
- `holyc-inference/MASTER_TASKS.md:2920-2921` records completed validation for the dispatch transcript and reset/scrub helpers.
- TempleOS keeps the matching OS workstreams open at `MODERNIZATION/MASTER_TASKS.md:271-272`.

Assessment:
The discrepancy may be intentional if helper-level inference work does not close the parent workstream. The risk is that Sanhedrin or release gates may count IQ completion as capability readiness while the parent WS rows and TempleOS counterpart remain open. The status taxonomy should distinguish "helper implemented" from "cross-repo invariant satisfied."

Remediation:
- Add explicit status text: WS9-28/29 helper implemented, blocked on TempleOS WS14-13/14 for trusted-session readiness.
- Link the inference IQ rows to the TempleOS WS rows in the gate output or audit checklist.

## Non-Findings

- No non-HolyC core implementation drift was found in the audited GPU helper files.
- No networking code, guest networking enablement, WS8 execution, or network-dependent package flow was found in the inspected evidence.
- TempleOS correctly keeps WS14-13 and WS14-14 open, so this audit is not treating the missing OS-side lifecycle as a completed-task violation.

## Verification Commands

```bash
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/reset_scrub.HC | sed -n '1,520p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/dispatch_transcript.HC | sed -n '1,260p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/book_of_truth_bridge.HC | sed -n '1,260p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/inference-secure-gate.sh | sed -n '55,75p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '235,285p'
rg -n "GPUResetScrub|GPUDispatchTranscript|BOT_GPU_EVENT_RESET|BOT_GPU_EVENT_SCRUB|BOT_GPU_EVENT_DISPATCH|GPU reset|memory scrub|dispatch transcript|WS14-13|WS14-14" /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md -S
```
