# Cross-Repo Audit: Token Book-of-Truth Emission Ledger Schema Drift

Date: 2026-04-29T18:48:57+02:00

Scope: Retroactive cross-repo invariant check between `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `d9c3b620dbe9cf8bde884ed11c8ec1df99a68e89` and `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `485af0ea41a239c8393542d6e0e2fc5944f30f53`.

This audit was read-only against TempleOS and holyc-inference. It did not run QEMU or any VM command, did not inspect live loop liveness, and did not modify trinity source code.

## Question

Does the holyc-inference per-token `Book-of-Truth` emission tuple correspond to an appendable TempleOS Book-of-Truth ledger event?

Short answer: no. holyc-inference now has deterministic, no-partial token emission helpers, but the produced six-cell tuple is a worker-local diagnostic record, not a TempleOS ledger event schema. It lacks TempleOS `event_type`, `source`, `payload`, sequence/hash-chain identity, and serial append proof, so current token emission evidence cannot be consumed as proof that TempleOS recorded the token in the Book of Truth.

## Findings

1. WARNING: holyc-inference's token emission tuple is not a TempleOS Book-of-Truth entry.
   - Evidence: TempleOS defines Book-of-Truth event constants and source constants, including `BOT_EVENT_VERIFY_FAIL`, `BOT_EVENT_TAMPER_FAULT`, `BOT_EVENT_SEAL_FAULT`, and `BOT_SOURCE_EXCEPTION`; event/source decoders render those IDs as ledger taxonomy.
   - Evidence: holyc-inference defines `INFERENCE_BOT_EVENT_TUPLE_CELLS 6` and stages `{session_id, step_index, token_id, logit_q16, policy_digest_q64, profile_mode}`.
   - Impact: a Sanhedrin parser or future TempleOS bridge cannot treat the inference tuple as an appendable ledger record without inventing a lossy mapping after the fact.
   - Required closure: define a shared token ledger ABI with explicit `bot_event_type`, `bot_source`, `payload_marker`, payload fields, and TempleOS schema version.

2. WARNING: blocked token emissions are status-only and do not produce a ledger failure tuple.
   - Evidence: holyc-inference emits only when `profile_mode == secure` and `policy_digest == expected_policy_digest`; otherwise it sets `INFERENCE_BOT_STATUS_BLOCKED` and `event_count = 0`.
   - Evidence: the Python harness asserts that digest mismatch preserves the event buffer while publishing blocked status.
   - Impact: a policy-digest mismatch can be represented as a local blocked status without a corresponding TempleOS `BOT_EVENT_VERIFY_FAIL` record. This weakens the secure-local audit trail because rejected token attempts are exactly the events that should be visible to the control plane.
   - Required closure: blocked token attempts should produce a deterministic failure event mapping, for example `BOT_EVENT_VERIFY_FAIL` with a token-policy payload marker and source chosen by the TempleOS integration point.

3. WARNING: the worker tuple has no TempleOS source taxonomy.
   - Evidence: TempleOS sources are `kernel`, `cli`, `irq`, `msr`, `exception`, `io`, and `disk`; source status readers aggregate counts by those categories.
   - Evidence: the holyc-inference tuple stores only `profile_mode` as its final lane and has no field for `BOT_SOURCE_*`.
   - Impact: token evidence cannot answer whether an inference token came from a CLI request, kernel-controlled generation path, exception/fault recovery path, or future device/IO path. Cross-repo dashboards would have to guess source ownership.
   - Required closure: add a source field to the shared ABI or declare a fixed source mapping for token-generation events and enforce it in TempleOS before append.

4. WARNING: the token digest is not Book-of-Truth append proof.
   - Evidence: holyc-inference hashes the six-cell tuple plus status/count with FNV constants.
   - Evidence: TempleOS ledger state includes event/source IDs, sequence, timestamp, payload, append logic, and hash-chain verification; `BookTruthAppend(...)` is the operation that makes a record part of the ledger.
   - Impact: a token tuple digest proves local worker determinism, not that the Book of Truth synchronously emitted bytes to COM1, advanced sequence, or preserved hash-chain continuity.
   - Required closure: token reports should include TempleOS append evidence: sequence number, previous/current entry hash or digest, serial append status, and fail-stop state when append fails.

5. INFO: no direct LAWS.md source violation was found in this pass.
   - The reviewed code remains HolyC in core/runtime paths, this audit did not observe networking additions, and no QEMU/VM command was executed. The issue is cross-repo contract drift between a worker-local diagnostic tuple and TempleOS's authoritative ledger schema.

## Suggested Gate

Add a Sanhedrin cross-repo check that fails token-emission readiness claims unless all of these are true:

- holyc-inference token emission evidence includes TempleOS event/source fields, not only worker tuple lanes.
- blocked token attempts map to a TempleOS-visible failure event instead of disappearing as `event_count=0`.
- TempleOS owns the final append call and returns append proof containing sequence/hash-chain identity.
- tests prove the same token event can be decoded by TempleOS `BookTruthEventName`/`BookTruthSourceName` semantics and by holyc-inference replay code.

## Evidence Commands

```
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC | sed -n '1,135p;1858,1945p;2568,2638p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/inference.HC | sed -n '1,55p;3371,3486p;3670,3806p;4590,4790p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_iq1791_bot_emit.py | sed -n '1,115p;500,630p'
rg -n "BOT_EVENT|BOT_SOURCE|INFERENCE_BOT_EVENT_TUPLE|BookTruthAppend|VERIFY_FAIL|TAMPER|SEAL" /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests -g '*.HC' -g '*.py'
```
