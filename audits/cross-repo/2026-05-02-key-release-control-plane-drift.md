# Cross-Repo Audit: Key-Release Control-Plane Drift

Timestamp: 2026-05-02T01:02:09+02:00

Scope: Cross-repo invariant check across TempleOS and holyc-inference. TempleOS and holyc-inference were read-only. No QEMU or VM command was executed.

Audited heads:
- TempleOS: `9f3abbf26398`
- holyc-inference: `2799283c9554`
- Sanhedrin audit branch: `codex/sanhedrin-gpt55-audit`

Relevant laws and audit rules:
- Law 2: TempleOS guest must remain air-gapped. No network or VM action was performed in this audit.
- Law 5 / North Star Discipline: audit work must surface concrete implementation risk, not bookkeeping.
- Sanhedrin sovereign-throughput rule: flag CRITICAL if trust decisions such as quarantine promotion, key release, or attestation verification are delegated solely to inference worker docs.

## Summary

The Trinity policy docs agree that TempleOS owns the trust/control plane and that trusted-load/key-release flows require attestation plus policy-digest parity. The implementation state does not yet match that invariant: holyc-inference has a concrete key-release verifier requiring `templeos_signed_approval`, while TempleOS still marks its attestation verifier and key-release gate tasks open and exposes no matching signed-approval or key-release primitive in the audited source.

Findings: 4 total; 1 CRITICAL, 3 WARNING.

## Evidence

TempleOS control-plane policy says TempleOS owns policy, quarantine/promotion authority, key release, and Book-of-Truth source-of-truth duties:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:43`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/LOOP_PROMPT.md:54`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/LOOP_PROMPT.md:56`

TempleOS also says trusted-load/key-release flows require worker-plane attestation evidence and policy digest parity:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:45`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:46`

But the TempleOS queue still has these control-plane implementation tasks open:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:276` (`WS14-18` attestation evidence verifier)
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:277` (`WS14-19` policy-digest handshake validation)
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:278` (`WS14-20` key-release gate)

holyc-inference has already implemented the worker-side key-release verifier with a `templeos_signed_approval` input:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/key_release_gate.HC:4`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/key_release_gate.HC:7`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/key_release_gate.HC:29`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/key_release_gate.HC:77`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/key_release_gate.HC:82`

TempleOS Book-of-Truth model promotion currently covers import, parse, verify, deterministic run, build attestation, and promotion events, but the exposed APIs do not include a key-release decision or signed approval primitive:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/KExts.HC:113`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/KExts.HC:126`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC:13740`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC:14022`

## Findings

### CRITICAL: Key-release trust decision is implemented only on the worker side

holyc-inference has a concrete key-release verifier that treats `templeos_signed_approval`, attestation evidence, and policy digest parity as the three release inputs. TempleOS, the documented trust/control plane, still has the attestation verifier, policy-digest validation, and key-release gate as open tasks. This creates a split where the runtime can model or report key-release success/failure before the TempleOS control plane has a corresponding authority surface to issue or log that decision.

Impact: a future integration could wire inference-side `InferenceKeyReleaseStatus(...)` into trusted dispatch using a caller-supplied approval bit rather than a TempleOS-originated, Book-of-Truth-recorded approval. That is exactly the trust-delegation shape Sanhedrin is instructed to flag as CRITICAL.

Recommended closure: implement the TempleOS-side key-release authority first, or mark inference key release as non-authoritative simulation until TempleOS exposes a signed/local approval decision that is logged by the Book of Truth and consumed by the worker.

### WARNING: The approval term is stronger than the available TempleOS artifact

The inference contract names the first proof `templeos_signed_approval`, but the audited TempleOS source shows no key-release approval API or signature artifact. Existing TempleOS model gates emit Book-of-Truth events and status rows, which are audit evidence, not a signed approval token with a defined verifier input format.

Impact: "signed approval" can drift into an informal boolean, weakening the control-plane boundary without tripping text-only policy-sync checks.

Recommended closure: define the approval artifact shape in TempleOS before accepting it in inference: issuer, payload fields, replay protection, digest/signature width, Book-of-Truth event marker, and fail-closed parse rules.

### WARNING: Key-release is not represented in Book-of-Truth model gate status

`BookTruthModelGateStatus` accounts for profile events, import schema failures, verify failures, deterministic parity events, build events, and promotion gate outcomes. It does not account for key-release approvals, denials, policy-digest mismatch rows, or attestation verification rows.

Impact: even after inference emits key-release pass/fail, Sanhedrin cannot reconstruct a trusted-run decision from the TempleOS Book-of-Truth model gate summary. This weakens the stated source-of-truth role of TempleOS for key release.

Recommended closure: add a distinct Book-of-Truth marker/gate bit for key-release approval/denial and include it in the model gate status summary before trusted dispatch consumes the worker-side gate.

### WARNING: Text parity checks can pass while implementation parity is absent

The trinity policy-sync script checks that docs mention "attestation/policy-digest handshake" and "attestation evidence + policy digest match." That catches dropped policy language, but it does not verify that TempleOS has implemented the corresponding verifier/gate while inference has already implemented its worker-side handshake.

Impact: docs can remain synchronized while the executable trust boundary is inverted or incomplete.

Recommended closure: add a source-level parity check that fails when holyc-inference contains `InferenceKeyReleaseHandshakeVerifyChecked` but TempleOS lacks the matching key-release authority symbol and Book-of-Truth event marker.

## Commands Run

- `git status --short --branch` in TempleOS, holyc-inference, and Sanhedrin audit worktree.
- `git rev-parse --short=12 HEAD` in TempleOS, holyc-inference, and Sanhedrin audit worktree.
- `rg -n` source/policy scans for `key-release`, `attestation`, `policy digest`, `signed approval`, `BookTruthModel`, and `secure-local`.
- `nl -ba ... | sed -n ...` evidence reads for the cited files.

No source code in TempleOS or holyc-inference was modified.
