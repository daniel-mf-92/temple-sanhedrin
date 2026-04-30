# Cross-Repo Per-Token Book-of-Truth Authority Drift Audit

Timestamp: 2026-04-30T09:37:15+02:00

Audit owner: gpt-5.5 sibling, retroactive / historical scope only

Repos examined:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `2e3b9750875e609cbe8495e03fb26087e78ee5f1`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `2799283c9554bea44c132137c590f02034c8f726`
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit` at pre-commit `7fc647484c5f0fb64968b2852bfb745d6aa742d1`

Audit angle: cross-repo invariant check. No TempleOS or holyc-inference source code was modified. No QEMU or VM command was executed. No WS8 networking task, socket, NIC, TCP/IP, UDP, DNS, DHCP, HTTP, TLS, package download, liveness watcher, or current-iteration compliance loop was executed.

## Expected Invariant

The phrase "per-token Book-of-Truth event" must mean a TempleOS-authoritative ledger append, or it must be explicitly marked as worker-local preflight telemetry. Under Laws 3, 8, 9, and 11, a compliant token ledger event needs TempleOS control-plane authority, synchronous append semantics, hardware-proximate serial evidence, immutable sequence/hash context, and local-only handling. The inference worker can prepare token evidence, but it cannot become the Book of Truth by writing a caller-owned buffer.

## Summary

Found 5 findings: 4 warnings and 1 info.

holyc-inference now contains an extensive per-token "Book-of-Truth" emission family for `BotTokenEmit*`, with IQ records marking the work complete. The implementation is HolyC and fail-closed for local tuple publication, but the published object is a six-cell caller buffer plus a digest, not a TempleOS Book-of-Truth append. TempleOS currently has profile and model/quarantine Book-of-Truth surfaces, but no matching token event API, source ID, sequence/hash bridge, or key-release/policy-digest verifier for worker token events.

This is not an air-gap breach. It is an authority-boundary drift: worker-local replay parity is being named like sovereign ledger emission before the TempleOS control plane exposes the matching token-event append contract.

## Finding WARNING-001: Worker-local token tuple publication is named as Book-of-Truth emission

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy & Hardware Proximity
- Law 11: Book of Truth Local Access Only

Evidence:
- `holyc-inference/src/model/inference.HC:3371-3378` labels the API as a "per-token Book-of-Truth emission gate for secure-local replay logs."
- `holyc-inference/src/model/inference.HC:3379-3516` implements `BotTokenEmitChecked`, stages `{session_id, step_index, token_id, logit_q16, policy_digest_q64, profile_mode}`, and copies it into a caller-provided `event_buffer` only when `profile_mode` is secure and `policy_digest_q64 == expected_policy_digest_q64`.
- `holyc-inference/src/model/inference.HC:3507-3515` publishes only the staged tuple plus `{event_status,event_count,event_digest_q64}`; it does not call a TempleOS `BookTruthAppend`, serial `out 0x3F8`, sealed-page writer, or hash-chain append.
- A content scan found `BotTokenEmit` / `InferenceBookOfTruthTokenEventEmit` references in 8 holyc-inference files and 0 TempleOS files.

Assessment:
The worker implementation is useful structured telemetry, but it is not the Book of Truth. Treating `INFERENCE_BOT_STATUS_EMITTED` as a ledger append would overstate compliance with Laws 3, 8, and 11 because the event can exist without TempleOS sequence, hash, UART, sealed-page, or local-only retention context.

Required remediation:
- Rename or document the API as `worker_token_evidence` until TempleOS owns the append.
- Require a separate field for `templeos_booktruth_seq` / `templeos_entry_hash` before any report calls a token tuple "emitted to Book of Truth."
- Keep the current tuple digest as preflight evidence, not final ledger proof.

## Finding WARNING-002: TempleOS has model/profile ledger gates but no per-token ledger contract

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy & Hardware Proximity
- Law 5: North Star Discipline

Evidence:
- `TempleOS/Kernel/BookOfTruth.HC:12645-12669` logs profile changes through `BookTruthAppend`.
- `TempleOS/Kernel/BookOfTruth.HC:12898-13161` logs model import, parse, verify, deterministic eval, and promotion decisions.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:261-265` marks model manifest, hardening, deterministic gate, and profile/model/gate events complete.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:276-278` still leaves attestation verifier, policy-digest validation, and key-release gate open.
- A targeted search for token-oriented Book-of-Truth APIs in TempleOS core/control docs found only unrelated model-tokenizer metadata and DMA "map token" wording, not an inference token event append surface.

Assessment:
TempleOS has made real control-plane progress, but the existing completed surfaces stop at profile/model/gate events. The inference worker has moved ahead to per-token event tuples without a corresponding TempleOS source ID, payload layout, append function, or status reader. That makes cross-repo proof ambiguous: a worker can say token event emitted while the control plane has no canonical place to receive it.

Required remediation:
- Add a TempleOS-owned token event schema before accepting worker token emission as Book-of-Truth evidence.
- Define source ID, event type, payload packing, sequence/hash fields, serial prefix, and local-only retention class.
- Keep WS14-18 through WS14-20 blocking any trusted per-token ledger claim.

## Finding WARNING-003: Policy digest equality is caller-supplied rather than TempleOS-authoritative

Applicable laws:
- Law 8: Book of Truth Immediacy & Hardware Proximity
- Law 9: Resource Supremacy / Crash on Log Failure
- Cross-repo split-plane trust rule from TempleOS `MASTER_TASKS.md`

Evidence:
- `holyc-inference/src/model/inference.HC:3452-3462` emits when `profile_mode == INFERENCE_BOT_PROFILE_SECURE` and `policy_digest_q64 == expected_policy_digest_q64`.
- `holyc-inference/src/runtime/policy_digest.HC:27-34` initializes worker-side policy guard globals to enabled defaults.
- `holyc-inference/src/runtime/policy_digest.HC:86-172` computes a worker digest over caller-provided policy booleans plus current inference profile.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:43-46` says TempleOS remains the trust/control plane and trusted-load/key-release requires attestation evidence plus policy digest match.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:276-278` keeps the TempleOS attestation verifier, policy-digest handshake, and key-release gate open.

Assessment:
The worker fail-closed comparison is only as strong as the source of `expected_policy_digest_q64`. Without a TempleOS-signed expected digest or ledger anchor, the same worker plane can compute both the presented digest and the expected digest. That is acceptable for preflight tests but not for a trusted Book-of-Truth token append.

Required remediation:
- Make token-event emit require a TempleOS-issued expected digest proof, not a raw caller number.
- Include the TempleOS policy digest entry sequence/hash in the token event tuple.
- Treat self-matched worker digests as `preflight_pass`, not `trusted_emit`.

## Finding WARNING-004: IQ completion records and actual symbol names disagree

Applicable laws:
- Law 5: North Star Discipline
- Law 6: Queue Health / traceability

Evidence:
- `holyc-inference/MASTER_TASKS.md:3916-3918` marks IQ-1791 through IQ-1793 complete for `InferenceBookOfTruthTokenEventEmitChecked*` symbols.
- `holyc-inference/MASTER_TASKS.md:2679` also says IQ-1791 added `InferenceBookOfTruthTokenEventEmitChecked`.
- The actual current implementation uses `BotTokenEmitChecked`, `BotTokenEmitCommitOnly`, `BotTokenEmitPreflightOnly`, and subsequent `BotTokenEmit*` wrappers in `src/model/inference.HC`.
- The targeted scan found no implemented `InferenceBookOfTruthTokenEventEmitChecked` symbol in current source output; the shorter `BotTokenEmit*` family is what exists.

Assessment:
The shorter symbol names help avoid identifier compounding, but the task ledger now points to names that do not exist. That weakens retroactive traceability and makes symbol-based gates unreliable: a future Sanhedrin check for the ledger-stated name would fail, while a check for the actual name would not prove that the promised Book-of-Truth authority exists.

Required remediation:
- Update the task ledger wording or add a compatibility note mapping promised names to actual symbols.
- Make any future release gate verify behavior and authority fields, not only symbol names.
- Add an audit-only invariant: "worker token evidence symbol present" is not equivalent to "TempleOS Book-of-Truth append present."

## Finding INFO-001: Reviewed implementation remains HolyC-only and no guest networking path was touched

Applicable laws:
- Law 1: HolyC Purity
- Law 2: Air-Gap Sanctity

Evidence:
- The reviewed runtime implementation files are HolyC under `holyc-inference/src/`.
- Test harnesses are Python under `holyc-inference/tests/`, which LAWS.md explicitly allows for inference validation scripts.
- This audit ran only read-only filesystem and git commands; no VM or QEMU command was executed.

Assessment:
No direct Law 1 or Law 2 violation was found in this pass. The risk is semantic: "Book-of-Truth emission" is being used for worker-local evidence before TempleOS has the matching sovereign append contract.

## Non-Findings

- No TempleOS or holyc-inference source file was edited.
- No QEMU or VM command was executed.
- No WS8 networking task was executed.
- No networking stack, NIC driver, socket, TCP/IP, UDP, TLS, DHCP, DNS, HTTP, or remote runtime service was added or enabled.
- No live liveness watching, process restart, or current-iteration compliance loop was performed.

## Read-Only Verification Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
git rev-parse HEAD
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/inference.HC | sed -n '3340,3585p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/policy_digest.HC | sed -n '1,210p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC | sed -n '12620,13340p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '30,60p;250,285p'
rg -n "BookTruth.*Token|Token.*BookTruth|Inference.*Token|model.*token|token_id|sampled_token|logit" -S /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/KExts.HC /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md
python3 - <<'PY'
from pathlib import Path
for root in [Path('/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS'), Path('/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference')]:
    hits = []
    for p in root.rglob('*'):
        if not p.is_file() or '.git' in p.parts or 'automation/logs' in str(p) or 'bench/results' in str(p):
            continue
        try:
            s = p.read_text(errors='ignore')
        except Exception:
            continue
        if any(token in s for token in ('BotTokenEmit', 'InferenceBookOfTruthTokenEventEmit', 'BookTruthToken', 'BOOK_OF_TRUTH_LOCAL', 'TOKEN_RESULT')):
            hits.append(p.relative_to(root))
    print(root.name, len(hits))
    for p in hits[:40]:
        print(' ', p)
PY
```
