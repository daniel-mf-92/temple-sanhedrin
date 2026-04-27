# Cross-Repo Audit: Token Book-of-Truth Control-Plane Drift

Timestamp: 2026-04-27T20:47:22Z

Scope:
- TempleOS head: `5810b24301784186266c8b83c0131dea12a76bdc`
- holyc-inference head: `b8a4fc8b7dd7cb2175ff3e4e8f051a7d4b19ca7d`
- Audit angle: cross-repo invariant check, historical/static only. No liveness watching and no VM/QEMU execution.

## Summary

The current inference repo treats `InferenceBookOfTruthTokenEventEmitChecked` / `BotTokenEmitChecked` as completed Book-of-Truth token emission work, but the implementation only stages a six-cell tuple in caller memory and computes a digest. TempleOS still defines the Book of Truth as a local control-plane ledger with fixed source taxonomy, COM1/serial liveness state, and append/fail-stop policy. That is a cross-repo drift: inference has a useful event proposal format, but it is not yet an acknowledged Book-of-Truth write.

Finding count: 4

## Findings

### CRITICAL: Inference marks token events as emitted without TempleOS ledger append acknowledgement

Evidence:
- `holyc-inference/MASTER_TASKS.md` marks IQ-1791 through IQ-1799 complete as Book-of-Truth token event emit/hardening work.
- `holyc-inference/src/model/inference.HC` defines `INFERENCE_BOT_STATUS_EMITTED` and writes only `event_buffer[lane]`, `*out_event_status`, `*out_event_count`, and `*out_event_digest_q64` in `BotTokenEmitChecked`.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md` says TempleOS in `secure-local` remains the trust/control plane and Book-of-Truth source of truth; the inference runtime is an untrusted worker plane.

Impact:
- The worker plane can report `EMITTED` even though no TempleOS `BookTruthAppend(...)` acknowledgement, serial liveness check, or ledger seal result is part of the tuple.
- This conflicts with LAWS.md Law 8/9 semantics: Book-of-Truth recording must be synchronous and fail-closed in the log path. A worker-memory tuple is not yet a log record.

Required fix:
- Rename the inference status/contract to `PROPOSED` or `STAGED` until a TempleOS control-plane adapter consumes the tuple and returns a ledger append acknowledgement.
- Add an explicit `ledger_ack_seq` or `book_truth_append_status` field that is produced only by TempleOS, not by the inference worker.

### WARNING: Token tuple has no TempleOS event/source mapping

Evidence:
- TempleOS `Kernel/BookOfTruth.HC` source taxonomy is currently `BOT_SOURCE_KERNEL`, `CLI`, `IRQ`, `MSR`, `EXCEPTION`, `IO`, and `DISK`.
- Inference token tuples contain `{session_id, step_index, token_id, logit_q16, policy_digest_q64, profile_mode}` only.

Impact:
- There is no canonical mapping for per-token inference events into TempleOS `BOT_EVENT_*` plus `BOT_SOURCE_*`.
- Sanhedrin and TempleOS coverage CLIs cannot distinguish genuine token ledger entries from generic note/CLI records without an agreed event ID and source.

Required fix:
- Define a TempleOS-side event family for inference token events and an allowed source path, or explicitly state that inference tuples must be wrapped by a TempleOS kernel/control-plane event before entering the ledger.

### WARNING: `EMITTED` does not encode serial-dead or log-failure outcomes

Evidence:
- TempleOS serial core checks COM1 transmit readiness via `BOT_COM1_BASE + BOT_COM1_LSR` and maintains `bot_serial_dead`.
- Inference status is only `BLOCKED` or `EMITTED`; the status domain has no serial-dead, append-failed, seal-failed, or halt-required outcome.

Impact:
- A secure-local token can become `EMITTED` when policy digests match, even if the only real Book-of-Truth-compliant result should be fail-stop on log failure.
- This weakens the Law 9 invariant at the cross-repo contract boundary.

Required fix:
- Reserve worker statuses for policy preflight only, and add a separate TempleOS-owned result enum for append/serial outcomes.

### WARNING: Completed task log references missing harness files

Evidence:
- `holyc-inference/MASTER_TASKS.md` claims harnesses for IQ-1792, IQ-1793, and IQ-1795 under long `tests/test_inference_book_of_truth_...` filenames.
- Current working tree check found those exact files missing. Present short-name harnesses include `tests/test_iq1791_bot_emit.py`, `tests/test_iq1795_bot_commit.py`, `tests/test_iq1796_bot_pre.py`, `tests/test_iq1797_bot_diag.py`, `tests/test_iq1798_bot_commit.py`, and `tests/test_iq1799_bot_pre.py`.

Impact:
- The historical task ledger overstates validation traceability for the Book-of-Truth token emit chain.
- This also obscures which tests Sanhedrin should expect for regression backfill.

Required fix:
- Amend task evidence to reference the actual short-name harnesses, or add compatibility wrappers with the claimed filenames.

## Non-Findings

- No guest networking or VM command was executed by this audit.
- No TempleOS or holyc-inference source code was modified.
- The inference implementation remains HolyC in runtime paths; Python files observed are host-side tests.

## Commands Run

- `git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD`
- `git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD`
- `rg` and `sed` read-only source inspections across `TempleOS/Kernel`, `TempleOS/MODERNIZATION`, `holyc-inference/src`, `holyc-inference/tests`, and `holyc-inference/MASTER_TASKS.md`
- Explicit missing-file check for the claimed IQ-1792/IQ-1793/IQ-1795 harness paths
