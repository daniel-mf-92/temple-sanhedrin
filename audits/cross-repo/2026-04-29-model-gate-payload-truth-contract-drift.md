# Cross-Repo Model Gate Payload Truth-Contract Drift Audit

Timestamp: 2026-04-29T10:50:49+02:00

Audit owner: gpt-5.5 sibling, retroactive / historical scope only

Repos examined:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `1ac34649eca35c2235532ee00b00b70a651b8801`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `485af0ea41a239c8393542d6e0e2fc5944f30f53`
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit`

Audit angle: cross-repo invariant check. No TempleOS or holyc-inference source code was modified. No QEMU, VM, WS8 networking, or live liveness command was executed.

## Summary

Found 5 findings: 1 critical, 3 warnings, and 1 info.

The repos agree at the policy level that `secure-local` is the default, model files are untrusted until quarantine and hash-manifest verification, and TempleOS is the trust/control plane. The drift is in the concrete Book-of-Truth event contract added by TempleOS commit `1ac34649`: a secure-local promotion denial is emitted as `BOT_EVENT_VERIFY_FAIL`, but its payload low success bit is set to `1`. The new status reader then treats that same payload bit as success before considering the failure event type, so a blocked promotion can be aggregated as `promote_ok`.

## Finding CRITICAL-001: Secure-local promotion denial encodes `ok=1`

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy & Hardware Proximity
- Law 5: North Star Discipline

Evidence:
- TempleOS secure-local policy says Book of Truth is always on, model quarantine plus hash verification is mandatory, and TempleOS owns quarantine/promotion authority at `TempleOS/MODERNIZATION/MASTER_TASKS.md:33-45`.
- `BookTruthModelPromote` sets `gate_mask|=BOT_MODEL_GATE_SECURE` when a secure-local promotion is not allowed, then emits `BOT_EVENT_VERIFY_FAIL` at `TempleOS/Kernel/BookOfTruth.HC:12550-12558`.
- That denial payload still sets the low payload bit to `1` at `TempleOS/Kernel/BookOfTruth.HC:12552-12556`.
- `BookTruthModelGateStatus` decodes `ok=payload&1` and increments `promote_ok` when `ok` is true before checking for a verify-fail gate at `TempleOS/Kernel/BookOfTruth.HC:12706-12713`.

Assessment:
The same ledger event carries a failure event type and a success bit. Because the new status reader trusts the success bit first, a denied secure-local promotion can be counted as a successful promotion. That corrupts the replay semantics of a security-relevant Book-of-Truth event and weakens Sanhedrin's ability to prove that trusted-load gates failed closed.

Required remediation:
- Encode secure-local promotion denials with low payload bit `0`.
- Make `BookTruthModelGateStatus` treat `BOT_EVENT_VERIFY_FAIL` as failure regardless of payload low bit.
- Add a fixture or source-level assertion for the exact secure-gate denial tuple: marker `BOT_MODEL_MARK_PROMOTE`, event `BOT_EVENT_VERIFY_FAIL`, `BOT_MODEL_GATE_SECURE` set, and `ok==0`.

## Finding WARNING-001: The host smoke test checks strings, not the event truth table

Applicable laws:
- Law 5: North Star Discipline
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- `automation/bookoftruth-model-gate-smoke.sh:30-39` verifies that flags, function names, one output string, and selected source snippets exist.
- The same smoke does not assert that a secure-local failure payload uses `ok==0`, nor that a failure event cannot be counted as `promote_ok`.
- `bash -n automation/bookoftruth-model-gate-smoke.sh && REPO_DIR="$PWD" bash automation/bookoftruth-model-gate-smoke.sh` passed during this audit despite the contradictory payload contract.

Assessment:
The smoke test can pass while the newly advertised gate-failure evidence is semantically inverted. This is a validation drift, not a source-language or air-gap breach.

Required remediation:
- Add fixture rows or static checks that cover success, schema failure, missing-verify failure, and secure-local gate failure.
- Require the smoke to fail if `BOT_EVENT_VERIFY_FAIL` promotion records can increase `promote_ok`.

## Finding WARNING-002: holyc-inference depends on TempleOS truth-plane semantics that are not yet mechanically replayable

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 5: North Star Discipline

Evidence:
- holyc-inference policy says `secure-local` is the default, model files are untrusted until quarantine plus hash-manifest verification, and trust decisions remain in the TempleOS control plane at `holyc-inference/MASTER_TASKS.md:26-30`.
- holyc-inference still lists profile transition audit events and Trinity policy drift gate work as incomplete at `holyc-inference/MASTER_TASKS.md:208-217`.
- TempleOS marks WS14-07 complete for Book-of-Truth events covering profile changes, model promotions, and gate failures at `TempleOS/MODERNIZATION/MASTER_TASKS.md:258-265`.

Assessment:
The inference worker plane is explicitly relying on TempleOS to be the authoritative truth plane, but the new TempleOS event format is not yet replay-safe enough for Sanhedrin to consume as an approval or denial proof. The policy is aligned, but the executable ABI is not.

Required remediation:
- Publish a shared promotion event truth table with fields for event type, marker, model id, gate mask, and success bit.
- Treat TempleOS WS14-07 as incomplete until the truth table is validated by a fixture that Sanhedrin and holyc-inference can both parse.

## Finding WARNING-003: The existing Trinity policy sync gate misses payload-level drift

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- `bash automation/check-trinity-policy-sync.sh` in holyc-inference passed with `21` checks and `drift=false`.
- The gate checks doc-pattern invariants such as secure-local default, quarantine/hash, and attestation/policy-digest presence; it does not inspect TempleOS `BOT_MODEL_MARK_PROMOTE` payload fields or status aggregation logic.

Assessment:
The current parity gate is useful for policy text drift, but it cannot catch a concrete Book-of-Truth ABI contradiction. A release process that treats this gate as sufficient would miss security-event semantics drift.

Required remediation:
- Add a Sanhedrin-owned read-only ABI check for model promotion events.
- Include negative fixtures where policy docs are aligned but event payloads are contradictory.

## Finding INFO-001: No new air-gap or core-language violation was found in this cross-repo pass

Applicable laws:
- Law 1: HolyC Purity
- Law 2: Air-Gap Sanctity

Evidence:
- TempleOS core changes in the audited surface are HolyC under `Kernel/`, and the added shell script is host-side automation.
- The inspected TempleOS diff did not add a QEMU/VM launch command, guest networking stack, NIC driver, sockets, DNS, DHCP, HTTP, TLS, or WS8 networking execution.
- holyc-inference policy continues to state models are loaded from disk only with no downloading, HTTP, or networking at `holyc-inference/MASTER_TASKS.md:20`.

Assessment:
The finding is confined to Book-of-Truth model gate semantics and cross-repo replayability. It is not an air-gap breach.

## Read-Only Verification Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '30,48p;258,266p;4199,4205p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC | sed -n '12540,12562p;12655,12720p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/bookoftruth-model-gate-smoke.sh | sed -n '1,60p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md | sed -n '20,32p;206,218p'
bash /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/check-trinity-policy-sync.sh
```
