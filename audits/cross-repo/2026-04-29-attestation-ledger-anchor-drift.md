# Cross-Repo Attestation Ledger Anchor Drift Audit

Timestamp: 2026-04-29T02:28:12+02:00

Audit owner: gpt-5.5 sibling, retroactive / historical scope only

Repos examined:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55` at `50c29152321e6be37da4f79b955f6743440e3b87` with pre-existing uncommitted source-worktree changes
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55` at `91b30c8ce1d2752279110a520308228e9a3b5ffd` with a pre-existing uncommitted `bench/perf_regression.py` change
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit` at `fc22601a1a1789fbcffe3b2b3f2f0fff7a44ddc3`

Audit angle: cross-repo invariant check. No TempleOS or holyc-inference source code was modified. No QEMU, VM, or WS8 networking command was executed.

## Summary

Found 5 findings: 4 warnings and 1 info.

This pass checked whether holyc-inference attestation and Book-of-Truth hook claims are anchored to the immutable TempleOS ledger identity that LAWS.md requires. The repos currently agree at the policy level that inference, token, tensor, GPU, and profile events must be Book-of-Truth observable, but they do not yet agree on the concrete proof tuple that would bind those claims to TempleOS ledger entries.

The drift is not guest networking. It is evidentiary: holyc-inference emits or stores attestation facts such as `policy_digest`, `nonce`, `trusted_models`, `iommu_active`, and `bot_gpu_hooks_active`, while TempleOS' canonical ledger identity is `{seq, tsc, event_type, source, payload, prev_hash, entry_hash}`. The reviewed inference artifacts do not carry the TempleOS `seq`, `prev_hash`, `entry_hash`, event ID, source ID, or payload marker needed for Sanhedrin to prove that an attestation claim corresponds to an immutable Book-of-Truth append.

## Finding WARNING-001: Inference attestation emits policy facts without TempleOS ledger anchors

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- `holyc-inference/src/runtime/attestation_manifest.HC:17-31` defines an `InferenceAttestationManifest` with session, profile, policy digest, nonce, trust counts, GPU/IOMMU state, and text lines.
- `holyc-inference/src/runtime/attestation_manifest.HC:243-320` emits line-oriented keys for `session_id`, `profile_name`, `policy_digest`, `profile_id`, `nonce`, `trusted_models`, `quarantine_blocks`, `gpu_dispatch_allowed`, `iommu_active`, and `bot_gpu_hooks_active`.
- `TempleOS/Kernel/BookOfTruth.HC:97-106` defines a canonical ledger entry as `seq`, `tsc`, `event_type`, `source`, `payload`, `prev_hash`, and `entry_hash`.
- `TempleOS/Kernel/BookOfTruth.HC:3-22` reserves canonical event IDs only through `BOT_EVENT_SERIAL_WATCHDOG`; no canonical attestation, policy, token, model, profile, tensor, or GPU event IDs are visible in this reviewed surface.

Assessment:
The attestation manifest is useful as local runtime evidence, but it is not a Book-of-Truth proof. A Sanhedrin verifier can inspect policy fields, but cannot join the manifest to the TempleOS hash chain because the manifest lacks ledger sequence and hash-chain anchors.

Required remediation:
- Add a shared proof tuple for trusted runtime sessions: `{event_type, source, payload_marker, seq, prev_hash, entry_hash, serial_liveness_ok}`.
- Treat bare attestation lines as unanchored until a TempleOS-generated append proof is present.
- Reserve or document canonical TempleOS event/source mapping for `policy_digest`, `attestation`, `model_load`, `profile_transition`, `token`, and `tensor_checkpoint`.

## Finding WARNING-002: GPU Book-of-Truth bridge can overwrite local records, so it must not be treated as the immutable ledger

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 9: Resource Supremacy / Crash on Log Failure

Evidence:
- `holyc-inference/src/gpu/book_of_truth_bridge.HC:36-54` defines an in-memory `BOTGPUBridge` ring with caller-supplied storage, capacity, count, head, and next sequence ID.
- `holyc-inference/src/gpu/book_of_truth_bridge.HC:140-163` writes the event into `bridge->events[bridge->head]`, advances `head`, and explicitly overwrites the oldest event when the bridge is full.
- `holyc-inference/src/gpu/book_of_truth_bridge.HC:166-217` records DMA, MMIO, and dispatch classes into that bridge.
- `TempleOS/Kernel/BookOfTruth.HC:108-118` maintains canonical ledger storage, head/count/sequence/hash globals separately from the inference bridge.

Assessment:
The bridge can be a staging or encoding helper, but its overwrite-on-full behavior is incompatible with an immutable Book-of-Truth record if downstream code treats bridge contents as the ledger. The cross-repo contract should state that bridge records are transient inputs and become compliant only after TempleOS appends them to the canonical ledger and returns an append-proof tuple.

Required remediation:
- Rename or document the bridge as a pre-ledger event encoder unless it receives a TempleOS append proof.
- Fail closed on bridge capacity exhaustion when running in `secure-local`, or require immediate TempleOS append before any overwrite.
- Bind each GPU bridge record to a TempleOS `{seq, entry_hash}` before it can satisfy `bot_gpu_hooks_active`.

## Finding WARNING-003: Token and tensor logging requirements have no visible TempleOS event/source namespace

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- `holyc-inference/MASTER_TASKS.md:23-24` says every inference call, every token, and every tensor checkpoint is loggable by the Book of Truth ledger.
- `holyc-inference/MASTER_TASKS.md:115` tracks WS8-03 for model-load, token, and anomaly Book-of-Truth hooks.
- `holyc-inference/MASTER_TASKS.md:213-219` requires profile transition audit events, policy digest output, attestation evidence bundles, and a key-release verifier requiring TempleOS approval.
- `TempleOS/Kernel/BookOfTruth.HC:3-22` and `:79-86` define event/source constants that stop at generic kernel/CLI/IRQ/MSR/exception/IO/disk categories.

Assessment:
The inference repo is designing richer event semantics than the currently visible TempleOS ledger vocabulary can represent directly. Without canonical event IDs or payload markers for token/tensor/model/profile/policy events, builders may encode security-relevant inference evidence as generic notes or host artifacts, weakening Sanhedrin's ability to verify exact coverage.

Required remediation:
- Reserve a TempleOS-owned namespace for inference events and sources, or publish a stable marker schema if `BOT_EVENT_NOTE` is intentional.
- Require token/tensor/profile/policy emitters to include a TempleOS event mapping in tests and host reports.
- Add a cross-repo parser fixture proving one inference token event can be decoded from TempleOS ledger fields without relying on ad hoc text.

## Finding WARNING-004: Attestation digest binding excludes TempleOS hash-chain state

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- `holyc-inference/src/runtime/attestation_manifest.HC:324-333` defines a policy-digest bind payload with policy digest, telemetry digest, total ops, total cycles, profile ID, nonce, and bound digest.
- `holyc-inference/src/runtime/attestation_manifest.HC:335-368` hashes those fields into `bound_digest_q64`.
- `TempleOS/Kernel/BookOfTruth.HC:97-106` has `prev_hash` and `entry_hash` as first-class ledger identity fields.
- `TempleOS/Kernel/KMain.HC:145-146` initializes the Book of Truth and immediately appends a boot event, making the ledger state part of the runtime trust base.

Assessment:
The bind payload proves consistency among inference-side policy and telemetry fields, but not that those fields were recorded by the TempleOS ledger. A malicious or stale worker could replay a consistent inference digest without proving it sits inside the current TempleOS hash chain.

Required remediation:
- Include TempleOS ledger anchors in the digest bind payload: latest accepted `seq`, `prev_hash`, `entry_hash`, and event/source/payload marker.
- Reject key release or `secure-local` promotion when the bind payload lacks a current TempleOS ledger anchor.
- Keep digest computation integer-only and HolyC-owned.

## Finding INFO-001: Air-gap posture was preserved during this audit

Applicable laws:
- Law 2: Air-Gap Sanctity

Evidence:
- No QEMU or VM command was executed.
- No WS8 networking task was executed.
- The audit only used read-only file inspection in TempleOS and holyc-inference worktrees.
- The reviewed policy text in `holyc-inference/MASTER_TASKS.md:20` still says models are loaded from disk only, with no downloading, HTTP, or networking.

Assessment:
This audit found attestation-to-ledger proof drift, not a guest networking breach. No networking stack, NIC driver, socket, TCP/IP, UDP, TLS, DHCP, DNS, or HTTP feature was added or enabled.

## Non-Findings

- No TempleOS or holyc-inference source file was edited.
- No QEMU or VM command was run.
- No live liveness watching, current-iteration compliance check, process restart, or real-time Sanhedrin audit was performed.
- Non-HolyC code was only inspected as host-side tooling; no core implementation code was added.

## Read-Only Verification Commands

```bash
sed -n '1,240p' LAWS.md
git -C /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55 status --short --branch
git -C /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55 rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55 status --short --branch
git -C /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55 rev-parse HEAD
nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/Kernel/BookOfTruth.HC | sed -n '1,130p'
nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/Kernel/KMain.HC | sed -n '135,170p'
nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/src/runtime/attestation_manifest.HC | sed -n '1,370p'
nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/src/gpu/book_of_truth_bridge.HC | sed -n '1,220p'
nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/MASTER_TASKS.md | sed -n '20,35p;110,150p;210,220p'
rg -n "BOT_EVENT_|BOT_SOURCE_|BookTruthAppend|prev_hash|entry_hash|bot_last_hash" /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/Kernel/BookOfTruth.HC
rg -n "policy_digest|attestation|bot_gpu_hooks_active|BOTGPUBridge|BOT_GPU_EVENT|Book of Truth" /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/src /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/MASTER_TASKS.md -g '*.HC' -g '*.md'
```
