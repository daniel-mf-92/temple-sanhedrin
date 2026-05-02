# Cross-Repo Trusted Model Ledger Contract Drift

Audit timestamp: 2026-05-02T08:12:50+02:00

Audit angle: cross-repo invariant check. This pass compared current TempleOS `HEAD` (`9f3abbf263982bf9344f8973a52f845f1f48d109`) against current holyc-inference `HEAD` (`2799283c9554bea44c132137c590f02034c8f726`) for trusted-model promotion and Book-of-Truth ledger coupling. Both sibling repositories were inspected read-only. No TempleOS or holyc-inference source was modified. No live liveness watching, process restart, QEMU/VM command, networking command, or WS8 networking task was executed. The TempleOS guest air-gap was not touched.

Analyzer: `audits/cross/2026-05-02-trusted-model-ledger-contract-drift.py`

## Summary

holyc-inference treats model import, manifest verification, quarantine, and promotion as mandatory trust gates for secure-local inference. TempleOS has a parallel Book-of-Truth model trust surface, but every public model trust transition still exposes a caller-controlled `emit_event` parameter and only appends the ledger row behind `if (emit_event)`. That creates a current-head contract drift: the inference side assumes trust gates are enforced and attestable, while the TempleOS producer side can mutate the corresponding trust state without immutable ledger evidence.

Finding count: 4 warnings.

## Evidence Matrix

| Check | Result |
| --- | ---: |
| TempleOS public `BookTruthModel*` state-mutating definitions with `emit_event=TRUE` parameter | 6 |
| TempleOS extern `BookTruthModel*` APIs with `emit_event=TRUE` parameter | 6 |
| TempleOS `if (emit_event)` guards in model trust implementation | 7 |
| TempleOS promote path mutates trusted state before optional ledger append | 1 |
| TempleOS secure-gate failure event can be skipped by `emit_event=FALSE` | 1 |
| holyc-inference quarantine contract names import/verify/promote workflow | 1 |
| holyc-inference promote requires verified quarantine stage | 1 |
| holyc-inference quant profile forbids disabled quarantine/manifest gates | 1 |
| holyc-inference policy digest includes quarantine and manifest gate bits | 1 |

## Findings

### WARNING-001: TempleOS trusted-model state changes can be made without Book-of-Truth events

Law: Law 3 Book of Truth Immutability; Law 8 Immediacy and Hardware Proximity; cross-repo invariant.

Evidence: `TempleOS/Kernel/BookOfTruth.HC:13474-13818` defines `BookTruthModelImport`, `BookTruthModelParseRun`, `BookTruthModelVerify`, `BookTruthModelDetRun`, `BookTruthModelBuildSet`, and `BookTruthModelPromote` with `Bool emit_event=TRUE`. Each function mutates `bot_models[...]` state and only appends `BOT_EVENT_NOTE` or `BOT_EVENT_VERIFY_FAIL` inside `if (emit_event)` blocks at lines 13522, 13566, 13610, 13656, 13726, 13789, and 13806. The public externs in `TempleOS/Kernel/KExts.HC:113-126` expose the same parameter.

Impact: a caller can import, parse, verify, determinism-check, build-check, or promote a model while suppressing the immutable evidence row. That conflicts with the shared secure-local story: these are trust-boundary transitions, not optional diagnostics.

### WARNING-002: holyc-inference assumes quarantine and manifest gates are hard, but TempleOS ledger evidence is optional

Law: Law 5 North Star Discipline; Law 8 Book of Truth Immediacy; cross-repo invariant.

Evidence: `holyc-inference/src/model/quarantine.HC:1-8` states the model workflow is import -> verify -> promote and that promotion requires secure-local profile plus verified quarantine state. `holyc-inference/src/runtime/quant_profile.HC:92-95` forbids quant-profile dispatch unless quarantine and manifest verification gates remain enabled. `holyc-inference/src/runtime/policy_digest.HC:135-161` includes quarantine and hash-manifest gates in the policy bitfield and digest.

Impact: inference can report that trust gates are enabled and digest-covered while TempleOS can still perform the related model ledger transitions without emitting immutable evidence. The two repos agree on gate vocabulary but not on whether the evidence is structurally mandatory.

### WARNING-003: promotion failure evidence can also be suppressed

Law: Law 3 Book of Truth Immutability; Law 9 Resource Supremacy / fail closed; cross-repo invariant.

Evidence: `TempleOS/Kernel/BookOfTruth.HC:13782-13794` handles secure-local promotion failure by constructing a `BOT_MODEL_MARK_PROMOTE` failure payload and appending `BOT_EVENT_VERIFY_FAIL` only when `emit_event` is true. The success/failure final append path at lines 13806-13810 is also conditional.

Impact: failed trusted-model promotion attempts are security-relevant evidence. If failures can be suppressed, a local audit cannot distinguish clean trust-gate enforcement from repeated unrecorded bypass attempts. The inference side’s quarantine and policy digest controls have no producer-side guarantee that failed attempts are visible in the ledger.

### WARNING-004: the current contract lacks a provenance-bearing handoff for inference trust bits

Law: Law 3 Book of Truth Immutability; Law 8 Book of Truth Immediacy; cross-repo invariant.

Evidence: `holyc-inference/src/runtime/policy_digest.HC:27-33` initializes trust-related policy booleans to enabled, and `InferencePolicyRuntimeGuardsSetChecked` at lines 61-83 accepts caller-supplied booleans after binary validation. I found no current importer that derives `quarantine_gate_enabled` or `hash_manifest_gate_enabled` from mandatory TempleOS Book-of-Truth rows. Meanwhile, the TempleOS producer can suppress the model rows that would be needed to prove those bits.

Impact: a policy digest can attest to enabled trust gates without binding those bits to immutable local ledger evidence. This is not a live network or air-gap violation, but it is a cross-repo proof gap for trusted model promotion.

## Recommended Follow-Up

- Remove caller-controlled `emit_event` from public TempleOS model trust APIs, or split read-only diagnostics from state-mutating operations.
- Make model trust transitions append Book-of-Truth evidence unconditionally; if append fails, follow the existing fail-stop doctrine.
- Define a shared trusted-model ledger ABI: import, manifest verify, parse, determinism, build, promotion success, and promotion failure rows.
- Make holyc-inference policy digest trust bits provenance-bearing, derived from local Book-of-Truth rows rather than default-on globals or caller-supplied booleans.

## Read-Only Verification

```bash
python3 audits/cross/2026-05-02-trusted-model-ledger-contract-drift.py
```

No QEMU/VM command was executed. No networking was enabled or touched.
