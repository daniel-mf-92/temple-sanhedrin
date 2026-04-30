# Cross-Repo Audit: Profile Transition Ledger Contract Drift

Timestamp: 2026-04-30T05:38:04+02:00

Audit angle: cross-repo invariant check for whether TempleOS Book-of-Truth profile events match holyc-inference `secure-local` / `dev-local` profile transition assumptions.

Repos reviewed:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `6417dc9f441cb426392503a1406f0bef9a74e17d`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `2799283c9554bea44c132137c590f02034c8f726`
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit` at `16ea823467925f1cd038ef3cadda35a70b0a078e`

No TempleOS or holyc-inference source file was modified. No QEMU, VM, WS8 networking, networking, package-download, or live liveness command was executed.

## Expected Cross-Repo Invariant

Security profile transitions are trust-plane events. TempleOS owns the canonical `secure-local` / `dev-local` decision and must record profile transitions in the Book of Truth. holyc-inference may keep worker-local profile state, but secure-local evidence should not rely on worker-only profile booleans or status strings.

A complete transition proof needs:
- TempleOS profile event type/source/payload semantics.
- Worker profile state and policy digest that reference the same profile ID.
- A shared vocabulary for transition reasons such as enter, promote, and block.
- Sanhedrin-readable evidence that joins worker runtime state to TempleOS ledger sequence/hash identity.

Finding count: 4 warnings.

## Findings

### WARNING-001: Profile IDs align, but transition semantics do not

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 5: North Star Discipline
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- TempleOS defines `BOT_PROFILE_SECURE_LOCAL 1` and `BOT_PROFILE_DEV_LOCAL 2` in `Kernel/BookOfTruth.HC:103-104`.
- holyc-inference defines `INFERENCE_PROFILE_SECURE_LOCAL 1` and `INFERENCE_PROFILE_DEV_LOCAL 2` in `src/runtime/profile.HC:10-11`.
- TempleOS records profile changes by packing `BOT_PROFILE_PAYLOAD_MARKER`, previous profile, and next profile into a generic `BOT_EVENT_NOTE` at `Kernel/BookOfTruth.HC:12539-12544`.
- holyc-inference's open WS16-06 asks for `profile_enter`, `profile_promote`, and `profile_block` Book-of-Truth events at `MASTER_TASKS.md:213`.

Assessment:
The numeric profile IDs are synchronized, which is good. The event vocabulary is not: TempleOS records a marker plus prev/next profile, while holyc-inference names semantic transition classes that do not exist in the TempleOS event ABI. Sanhedrin can count profile events, but cannot distinguish "entered secure-local at boot" from "promoted dev-local evidence" or "blocked a transition" without inference-specific interpretation outside the ledger.

Required remediation:
- Define a shared profile-transition payload with `{reason, prev_profile, next_profile, gate_mask, worker_policy_digest}` or reserve distinct TempleOS event IDs for enter/promote/block.
- Keep the existing numeric profile IDs, but make the transition reason part of the immutable ledger record.

### WARNING-002: Worker profile changes are local state mutations without TempleOS append acknowledgement

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- holyc-inference `InferenceProfileTrySetChecked(...)` validates the requested profile and directly updates `g_inference_profile_mode` at `src/runtime/profile.HC:36-43`.
- `InferenceProfileSetDevLocalChecked()` and `InferenceProfileSetSecureLocalChecked()` are thin wrappers over that local setter at `src/runtime/profile.HC:46-56`.
- The same file exposes `InferenceProfileStatus()` as a local profile ID getter at `src/runtime/profile.HC:81-85`.
- A read-only scan for `profile_enter`, `profile_promote`, `profile_block`, `InferenceProfile.*Book`, and `Profile.*Audit` found no worker-side append or acknowledgement path in `holyc-inference/src`.

Assessment:
The worker profile runtime is simple and HolyC-only, but it is not an auditable trust-plane transition. A worker can report profile `1` while TempleOS has no joined Book-of-Truth event proving who changed the profile, why it changed, which policy digest was active, or whether the transition was accepted by the control plane.

Required remediation:
- Treat `InferenceProfileStatus()` as worker-local telemetry until it is joined to a TempleOS profile append proof.
- Require profile setters used in secure-local paths to consume a TempleOS transition approval record or emit a pending transition request that TempleOS records before trust decisions proceed.

### WARNING-003: TempleOS profile events are currently aggregated inside model-gate status, not exposed as their own transition ledger contract

Applicable laws:
- Law 5: North Star Discipline
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- `BookTruthModelGateStatus(...)` counts profile marker events only when `marker==BOT_PROFILE_PAYLOAD_MARKER` and `entry->event_type==BOT_EVENT_NOTE` at `Kernel/BookOfTruth.HC:13106-13113`.
- The same status string reports `profile_evt`, `secure`, and `dev` together with model promotion/import/verify/deterministic-gate counters at `Kernel/BookOfTruth.HC:13147-13150`.
- `automation/bookoftruth-profile-smoke.sh` only checks that profile IDs, profile CLIs, externs, and boot wiring exist; it does not validate a semantic transition event contract.
- `automation/bookoftruth-model-gate-smoke.sh` asserts profile payload packing, but its required status literal is stale against the current `BookTruthModelGateStatus` output and does not independently parse profile transition records.

Assessment:
Profile evidence exists, but its main aggregation is tied to model-gate status. That makes profile transitions an implementation detail of a broader model gate report rather than a first-class cross-repo contract. holyc-inference WS16-06 expects profile transition audit events, but TempleOS has not exposed fields that would let Sanhedrin validate those specific transition classes.

Required remediation:
- Add a dedicated `BookTruthProfileTransitionStatus` or equivalent parser contract that reports transition reason, prev/next profile, source, last sequence, and last entry hash.
- Update smoke checks to validate profile event semantics, not just symbol presence and payload-marker packing.

### WARNING-004: Secure-on performance gates can pass worker-local profile checks without a TempleOS profile proof

Applicable laws:
- Law 5: North Star Discipline
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- TempleOS policy says performance wins only count with security controls enabled: IOMMU, Book of Truth, and policy gates at `MODERNIZATION/MASTER_TASKS.md:43-47`.
- holyc-inference policy mirrors that throughput claims must include `secure-local` measurements with audit hooks enabled at `MASTER_TASKS.md:26-30`.
- holyc-inference `Q8_0DotBenchRunDefaultSuiteSecureLocalAuditGate(...)` accepts caller-provided `profile_id` and `audit_hooks_active`, then passes when `profile_id==INFERENCE_PROFILE_SECURE_LOCAL` and hooks are active at `src/runtime/profile.HC:88-128`.
- TempleOS still has open trust-plane verifier tasks for continuous secure-local checks, attestation verification, policy-digest validation, and key-release gate at `MODERNIZATION/MASTER_TASKS.md:266-278`.

Assessment:
The worker gate is a useful local preflight, but it is not enough for secure-local performance accounting. Without a TempleOS profile transition proof and policy-digest join, benchmark evidence can truthfully pass a worker-local profile gate while still failing the cross-repo trust-plane invariant.

Required remediation:
- Require secure-on benchmark rows to include TempleOS profile event sequence/hash plus worker profile ID and policy digest.
- Sanhedrin should label worker-only secure-local profile gates as advisory until the TempleOS verifier tasks are complete.

## Non-Findings

- No HolyC purity violation was found in the reviewed profile-state surfaces.
- No networking or air-gap violation was found; no QEMU or VM command was run.
- Numeric profile IDs currently match across TempleOS and holyc-inference.

## Evidence Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC | sed -n '20,125p;680,780p;12505,12575p;13070,13155p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '31,55p;258,281p;2220,2238p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/profile.HC | sed -n '1,240p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md | sed -n '23,31p;207,219p;1138,1154p'
rg -n "profile_enter|profile_promote|profile_block|Profile.*Audit|Audit.*Profile|BookTruth.*Profile|BOT_PROFILE|PROFILE_PAYLOAD|InferenceProfile.*Audit|InferenceProfile.*Book" /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation -S
rg -n "BookTruthProfile|profile_evt|secure=|dev=|BOT_PROFILE_PAYLOAD_MARKER|BookTruthModelGateStatus" /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation -S
```
