# Cross-Repo GPU Policy Source-of-Truth Drift Audit

Timestamp: 2026-04-29T12:29:55+02:00

Audit angle: cross-repo invariant check between TempleOS secure-local control-plane ownership and holyc-inference GPU dispatch / performance gate inputs.

Repositories audited:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `63780d214b9b`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `485af0ea41a2`
- Sanhedrin audit repo: `/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55` at `d66efabb7eb7`

Safety posture: read-only against TempleOS and holyc-inference. No QEMU/VM command was run. No WS8 networking task, socket, TCP/IP, UDP, DNS, DHCP, HTTP, TLS, or package-network action was executed.

## Scope

This pass checked whether holyc-inference's GPU gate booleans and policy digest can be treated as authoritative under TempleOS' rule that TempleOS owns trust/control decisions while inference owns throughput work.

Primary evidence reviewed:
- `LAWS.md`
- TempleOS `MODERNIZATION/MASTER_TASKS.md`
- TempleOS `MODERNIZATION/LOOP_PROMPT.md`
- TempleOS `MODERNIZATION/AGENT_HOLYC_MODERN_OS_GUIDE.md`
- holyc-inference `src/gpu/policy.HC`
- holyc-inference `src/gpu/security_perf_matrix.HC`
- holyc-inference `src/runtime/policy_digest.HC`

## Findings

### WARNING-1: GPU dispatch authorization is caller-asserted, not TempleOS-proof-derived

TempleOS states that `secure-local` is the default, GPU is disabled unless IOMMU plus Book-of-Truth DMA/MMIO logging hooks are active, and TempleOS remains the trust/control plane for policy, audit authority, and key-release decisions (`MODERNIZATION/MASTER_TASKS.md:31-47`; `MODERNIZATION/LOOP_PROMPT.md:54-57`). The current TempleOS GPU/IOMMU integration tasks remain open, including IOMMU domain manager, BAR/MMIO allowlist, DMA lease model, reset/scrub, transcript capture, and fail-closed boot gate (`MODERNIZATION/MASTER_TASKS.md:267-278`).

holyc-inference's `GPUPolicyAllowDispatchChecked` accepts `iommu_enabled`, `bot_dma_log_enabled`, `bot_mmio_log_enabled`, and `bot_dispatch_log_enabled` as caller-supplied integer flags, then allows dispatch if all are true (`src/gpu/policy.HC:34-95`). It does not require a TempleOS-produced proof tuple such as a Book-of-Truth sequence, event/source/payload marker, entry hash, or boot-visible profile record.

Impact: the local inference gate is fail-closed for false flags, but true flags are not mechanically anchored to TempleOS control-plane evidence. A future caller can satisfy the worker-plane API by passing `1,1,1,1` without proving that TempleOS actually owns and logged those controls.

Recommended closure: replace raw hook booleans at trusted dispatch boundaries with a TempleOS-generated proof bundle: `{profile_id, iommu_domain_id, dma_hook_seq/hash, mmio_hook_seq/hash, dispatch_hook_seq/hash, policy_digest, bot_serial_live}`. Keep the inference helper as a pure verifier of that bundle.

### WARNING-2: Security/perf rows compress three Book-of-Truth hook classes into one boolean

holyc-inference's row gate takes a single `book_of_truth_gpu_hooks` flag plus `iommu_active` and `policy_digest_parity` (`src/gpu/security_perf_matrix.HC:408-467`). The fast-path wrappers snapshot and parity-check that same compressed boolean across long wrapper chains (`src/gpu/security_perf_matrix.HC:2440-2480`).

TempleOS policy separates the required controls: IOMMU enforcement, Book-of-Truth DMA/MMIO hooks, dispatch transcript capture, and fail-closed runtime behavior are separate work items (`MODERNIZATION/MASTER_TASKS.md:267-278`). The single worker-plane boolean cannot distinguish "DMA logging exists but MMIO logging is absent" from "all required GPU hooks are active and ledger-anchored."

Impact: secure-on performance evidence can appear policy-compliant while masking which control-plane prerequisite actually passed. That weakens Law 5 north-star evidence because throughput claims could be counted before each security control is independently proven.

Recommended closure: make the matrix row input carry separate proof statuses for `iommu`, `bot_dma`, `bot_mmio`, `bot_dispatch`, and `dispatch_transcript`, and include those fields in the snapshot digest.

### WARNING-3: Policy digest defaults assert strict posture before receiving TempleOS evidence

holyc-inference initializes runtime policy guard globals to enabled for IOMMU, Book-of-Truth DMA/MMIO/dispatch logs, quarantine, and hash-manifest gates (`src/runtime/policy_digest.HC:27-34`). The digest path then serializes those booleans into policy bits and digest lanes (`src/runtime/policy_digest.HC:135-168`).

TempleOS says missing or invalid attestation/digest evidence must fail closed (`MODERNIZATION/MASTER_TASKS.md:43-47`) and that workers must not own trust decisions (`MODERNIZATION/AGENT_HOLYC_MODERN_OS_GUIDE.md:17-22`). A default-true worker digest is not itself a control-plane attestation.

Impact: a digest can represent "all guard bits are true" before any TempleOS proof bundle is supplied. That creates an integration hazard where digest parity is confused with control-plane provenance.

Recommended closure: default all externally evidenced guard bits to `0` until TempleOS supplies a signed or Book-of-Truth-anchored proof record. The digest should encode both the booleans and the provenance sequence/hash that made them true.

### WARNING-4: Current Sanhedrin/TempleOS policy text has no executable source-of-truth contract for GPU gate inputs

TempleOS docs are explicit that profile, quarantine, and GPU policy must stay synchronized across Trinity loops and that profile/GPU changes must patch parity docs or create blockers (`MODERNIZATION/MASTER_TASKS.md:49-54`; `MODERNIZATION/LOOP_PROMPT.md:45-67`). They do not yet define an executable ABI for the exact values that holyc-inference may accept as `iommu_active`, `book_of_truth_gpu_hooks`, or `policy_digest_parity`.

Impact: the two repos can both remain HolyC-only and air-gap-safe while still disagreeing on the source of truth for GPU gate inputs. This is not a Law 1 or Law 2 violation; it is a cross-repo Law 5 warning because the secure-local throughput proof remains incomplete.

Recommended closure: add a Sanhedrin-owned contract fixture for GPU policy proof. It should reject any row or dispatch evidence unless each worker-plane gate input traces to a TempleOS Book-of-Truth event, profile status, and policy digest record with stable field names and reason-code mapping.

## Non-Findings

- No trinity source files were modified.
- No guest execution or VM/QEMU command was performed.
- The inspected core inference GPU policy code is HolyC and remains integer-only.
- The drift is contractual/source-of-truth drift, not a current networking or language-boundary breach.

## Summary

Findings: 4 warnings, 0 critical violations.

The current heads preserve the air-gap and HolyC boundary. The unresolved risk is that holyc-inference GPU policy and secure-on performance helpers verify caller-supplied booleans and local digests, while TempleOS policy requires trust-plane evidence to originate from TempleOS and the Book of Truth.
