# Cross-Repo Invariant Audit: Book-of-Truth Token ABI Drift

Timestamp: 2026-04-28T06:55:59+02:00

Auditor: gpt-5.5 sibling, retroactive/deep audit scope

Audit angle: cross-repo invariant check. No TempleOS or holyc-inference source code was modified, and no VM/QEMU command was executed.

Repos examined:
- TempleOS committed HEAD: `d103bb8fcb0a50bd787317688ff8d06ad1c3fba9`
- holyc-inference committed HEAD: `b8a4fc8b7dd7cb2175ff3e4e8f051a7d4b19ca7d`
- temple-sanhedrin local-codebase HEAD: `c95e1a3bf9fa7da03e9ca4459799e3949145df79`
- temple-sanhedrin audit worktree baseline: `0a5fe4274d3ff31aa8bb83eabca0860feeb3b31f`
- temple-sanhedrin branch: `codex/sanhedrin-gpt55-audit`

## Executive Summary

Found 5 findings: 4 warnings, 1 info.

The high-level Trinity policy gate is green: `check-trinity-policy-sync.sh` emitted 21 passing checks and 0 failures. The deeper invariant drift is below that doc-regex layer. TempleOS defines the Book of Truth as a kernel ledger entry stream with `event_type`, `source`, `payload`, `prev_hash`, `entry_hash`, and serial output semantics. holyc-inference now has token "Book-of-Truth" emission helpers, but those helpers write private six-cell replay tuples into caller buffers and do not bind to TempleOS `BOT_EVENT_*`, `BOT_SOURCE_*`, serial exfiltration, or the hash-chain entry ABI. That is not a live air-gap breach and not a source modification violation. It is a cross-repo contract drift that can let worker-plane evidence be mistaken for canonical TempleOS Book-of-Truth evidence.

## Finding WARNING-001: Inference token "Book-of-Truth events" are not TempleOS Book-of-Truth entries

Applicable laws and invariants:
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy & Hardware Proximity
- Trinity split-plane invariant: TempleOS remains the Book-of-Truth source of truth

Evidence:
- TempleOS defines `CBookOfTruthEntry` with `seq`, `tsc`, `event_type`, `source`, `payload`, `prev_hash`, and `entry_hash` fields in `Kernel/BookOfTruth.HC:97-105`.
- TempleOS declares `BookTruthAppend(I64 event_type,I64 source=BOT_SOURCE_KERNEL,I64 payload=0)` in `Kernel/BookOfTruth.HC:594`.
- holyc-inference defines a private token tuple length `INFERENCE_BOT_EVENT_TUPLE_CELLS 6` in `src/model/inference.HC:26`.
- holyc-inference `BotTokenEmitChecked` stages exactly `{session_id, step_index, token_id, logit_q16, policy_digest_q64, profile_mode}` in `src/model/inference.HC:3445-3450`, then writes those lanes to `event_buffer` in `src/model/inference.HC:3507-3515`.

Assessment:
The inference tuple is useful worker-plane telemetry, but it is not a TempleOS Book-of-Truth ledger entry. It lacks `event_type`, `source`, `payload` packing, sequence number, TSC, previous hash, entry hash, and serial emission semantics.

Risk:
Auditors or future gates can over-count private inference tuples as canonical Book-of-Truth evidence, weakening Law 3 and Law 8 review without an obvious failing test.

Required remediation:
- Rename worker-plane output to "Book-of-Truth candidate token telemetry" or similar until it is explicitly wrapped by TempleOS `BookTruthAppend`.
- Define a cross-repo ABI document that maps token telemetry into a TempleOS `BOT_EVENT_*` event type, source ID, payload layout, and hash-chain expectations.
- Require reports to distinguish `worker_tuple`, `templeos_ledger_entry`, and `serial_observed_entry`.

## Finding WARNING-002: No shared event/source ID has been reserved for inference token events

Applicable laws and invariants:
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy & Hardware Proximity
- Cross-repo invariant: TempleOS commitments must match holyc-inference assumptions

Evidence:
- TempleOS currently reserves `BOT_EVENT_INIT` through `BOT_EVENT_SERIAL_WATCHDOG`, numeric IDs 1 through 20, in `Kernel/BookOfTruth.HC:3-22`.
- TempleOS currently reserves source IDs only through `BOT_SOURCE_DISK`, numeric IDs 1 through 7, and sets `BOT_SOURCE_MASK_ALL ((1<<BOT_SOURCE_DISK)-1)` in `Kernel/BookOfTruth.HC:79-86`.
- TempleOS event helper defaults clamp event ranges to `BOT_EVENT_INIT` through `BOT_EVENT_SERIAL_WATCHDOG` in `Kernel/BookOfTruth.HC:1123-1137`.
- holyc-inference `BotTokenEmitChecked` never references `BOT_EVENT_*`, `BOT_SOURCE_*`, or a TempleOS token-event constant in `src/model/inference.HC:3371-3517`.

Assessment:
holyc-inference assumes token events can be emitted, but TempleOS has no committed canonical token event type or inference source ID. This is a schema drift, not a runtime breach.

Risk:
If inference token evidence is later bridged into TempleOS, it will need either a new event/source ID or an overloaded existing event. Overloading would make historical audits ambiguous because existing TempleOS range checks and source masks were written for the current ID set.

Required remediation:
- Reserve explicit TempleOS constants such as `BOT_EVENT_INFERENCE_TOKEN` and `BOT_SOURCE_INFERENCE` before treating token telemetry as Book-of-Truth evidence.
- Update source-mask and event-status helpers to include the new IDs.
- Add Sanhedrin checks that fail if holyc-inference emits a Book-of-Truth-labelled tuple without a matching TempleOS event/source reservation.

## Finding WARNING-003: Inference token emission has no serial or fail-stop semantics

Applicable laws:
- Law 8: Book of Truth Immediacy & Hardware Proximity
- Law 9: Resource Supremacy / Crash on Log Failure

Evidence:
- LAWS.md requires Book-of-Truth logging to compose an entry, emit bytes with `out 0x3F8`, write to the in-memory buffer, and seal if needed in the same instruction sequence.
- TempleOS `MASTER_TASKS.md:169-175` states the log is written synchronously with each act and the serial `out 0x3F8` is part of the operation being logged.
- TempleOS `MASTER_TASKS.md:196-204` states that inability to write the log must execute `HLT` and there is no fallback.
- holyc-inference `BotTokenEmitChecked` only writes staged lanes into `event_buffer` and output slots in `src/model/inference.HC:3507-3515`; its fail-closed branch reports `blocked` and `count=0` in `src/model/inference.HC:3452-3462`.

Assessment:
The inference helper correctly blocks on profile/digest mismatch for its own tuple contract, but it does not prove Law 8 immediacy or Law 9 fail-stop behavior. That is acceptable for worker-plane diagnostics only if the artifact is labeled as pre-ledger evidence.

Risk:
Secure-local benchmark or token generation reports could claim "Book-of-Truth emission" while only proving private buffer writes. That would undercut the "machine that cannot record must not run" invariant if used as release evidence.

Required remediation:
- For any secure-local claim, require observed TempleOS serial ledger rows in addition to inference tuple digests.
- Add an explicit `ledger_committed` or `serial_observed` field to worker reports, defaulting false unless the TempleOS side confirms the entry.
- Treat buffer-only worker emission as WARNING evidence, not PASS evidence, for Laws 8 and 9.

## Finding WARNING-004: Task ledger names no longer match implemented symbol names

Applicable laws:
- Law 4: Identifier Compounding Ban
- Law 5: North Star Discipline

Evidence:
- holyc-inference `MASTER_TASKS.md:3915-3923` marks IQ-1791 through IQ-1799 complete using long names like `InferenceBookOfTruthTokenEventEmitChecked...`.
- The actual committed source uses concise symbols including `BotTokenEmitChecked`, `BotTokenEmitCommitOnly`, `BotTokenEmitPreflightOnly`, `BotTokenEmitParity`, and related variants in `src/model/inference.HC:3379-4387`.
- Only one matching test harness file exists for this family, `tests/test_iq1791_bot_emit.py`; `find tests -maxdepth 1 -type f -name '*bot*emit*.py'` found that single file.

Assessment:
The source appears to have been remediated toward the identifier-compounding ban, but the task ledger still attests the old long symbol names and expected long test filenames. This is historical documentation drift inside holyc-inference, not a source-code violation in this audit.

Risk:
Retroactive audit and future enforcement scripts can misread IQ-1791 through IQ-1799 as implemented under names that do not exist. That makes provenance harder to verify and encourages repeated wrapper-task churn around the same feature.

Required remediation:
- Backfill the ledger rows with the actual concise symbol names or add a short note that the implementation was renamed during Law 4 remediation.
- Avoid treating long task text as the authoritative symbol contract; use source symbol extraction for enforcement.
- Keep future IQ entries aligned to the final committed symbol and harness names.

## Finding INFO-001: High-level Trinity policy sync is currently green

Applicable laws and invariants:
- Law 2: Air-Gap Sanctity
- Law 3: Book of Truth Immutability
- Trinity policy parity

Evidence:
- Running `bash automation/check-trinity-policy-sync.sh` in holyc-inference emitted a summary with `status=pass`, `drift=false`, `passed=21`, and `failed=0`.
- The same run confirmed secure-local default, dev-local air-gap/Book-of-Truth guardrails, quarantine/hash, GPU IOMMU/Book-of-Truth, attestation-digest, and Trinity drift guard patterns across inference, TempleOS, and Sanhedrin docs.

Assessment:
The drift in this report is below the current gate's regex surface. The doc-level parity guard is useful, but it does not verify event ABI compatibility, serial ledger commitment, source ID reservations, or worker tuple classification.

## Non-Findings

- No TempleOS guest networking stack, NIC driver, socket, TCP/IP, UDP, TLS, DHCP, DNS, HTTP, or remote runtime service was found or executed by this audit.
- No WS8 networking task was executed.
- No TempleOS or holyc-inference source file was modified.
- No QEMU or VM command was run; therefore no VM launch arguments were needed beyond this report's read-only evidence review.

## Read-Only Verification Commands

- `git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD`
- `git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD`
- `git -C /Users/danielmatthews-ferrero/Documents/local-codebases/temple-sanhedrin rev-parse HEAD`
- `bash automation/check-trinity-policy-sync.sh` from `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC | sed -n '1,120p'`
- `rg -n "BookTruthAppend|BOT_EVENT|BOT_SOURCE|CBookOfTruthEntry" /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/inference.HC | sed -n '3360,3745p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md | sed -n '3908,3925p'`
- `find /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests -maxdepth 1 -type f -name '*bot*emit*.py' -print`
