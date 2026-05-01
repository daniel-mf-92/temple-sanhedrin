# Cross-Repo Audit: Token Event Ledger Ingestion ABI Drift

Audit timestamp: 2026-05-01T01:31:18Z
Audit angle: cross-repo invariant check
Repos inspected read-only:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference`

No trinity source code was modified. No QEMU/VM command, WS8 networking task, live liveness check, package-manager command, or remote-service command was executed.

## Invariant Under Audit

The inference loop claims that generated inference events, especially per-token events, are logged to the Book of Truth. TempleOS must expose a compatible local HolyC ledger ingestion ABI for that claim to be true without violating LAWS.md Law 2, Law 3, Law 8, Law 9, and Law 11.

Expected invariant:
- `holyc-inference` emits a token/event tuple with a stable ABI.
- `TempleOS` accepts that tuple through a local HolyC Book-of-Truth API.
- TempleOS appends it synchronously through the existing `BookTruthAppend(...)` path, with no buffering, remote export, or network dependency.
- Failure is fail-closed: if the token event cannot be recorded, the trusted inference session cannot continue.

## Findings

### WARNING-001: holyc-inference marks per-token Book-of-Truth event emission complete, but TempleOS has no matching token-event ingestion API

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md` marks `IQ-1791` through `IQ-1799` complete for `InferenceBookOfTruthTokenEventEmitChecked...` helpers. The task text says these emit per-token Book-of-Truth events with immutable `{session_id,step_index,token_id,logit_q16,policy_digest_q64,profile_mode}` snapshots.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/inference.HC` implements the token event chain as staged caller-buffer writes and parity checks around `event_buffer`, `out_event_status`, `out_event_count`, and `out_event_digest_q64`.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/KExts.HC` exposes model lifecycle APIs only: `BookTruthModelImport`, `BookTruthModelParseRun`, `BookTruthModelDetRun`, `BookTruthModelBuildSet`, `BookTruthModelVerify`, `BookTruthModelPromote`, and status helpers. No `BookTruth...Token...` extern exists.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC` has model lifecycle append paths that pack `BOT_MODEL_MARK_*` payloads into `BOT_EVENT_NOTE` or `BOT_EVENT_VERIFY_FAIL`, but no token/session/step/logit/policy-digest payload intake.

Impact: the inference side can produce a deterministic token-event tuple, but the TempleOS trust/control plane has no audited local API to turn that tuple into a sealed Book-of-Truth record. The cross-repo contract is therefore aspirational, not executable.

### WARNING-002: token-event completion can be misread as Law 8/9-compliant ledger emission, but current implementation is only a worker-plane buffer commit

Evidence:
- `holyc-inference/src/model/inference.HC` snapshots inputs, writes staged events, and publishes tuple status/digest into caller-owned output slots.
- The implementation does not call a TempleOS `BookTruthAppend` equivalent, cannot check UART liveness, and cannot enforce Book-of-Truth resource supremacy.
- TempleOS Law 8 requires the Book of Truth to record synchronously and close to hardware; Law 9 requires the OS to stop before the log silently drops an event.

Impact: downstream reviewers could accept "event emitted" as "ledger appended". That creates a compliance blind spot: a token can be considered logged even when no TempleOS append occurred.

### WARNING-003: no shared status vocabulary maps inference token-event statuses to TempleOS gate/fail-stop states

Evidence:
- The inference helpers use statuses such as emitted/blocked via `INFERENCE_BOT_STATUS_*` and return sampling error codes.
- TempleOS model gates use model lifecycle state, `gate_mask`, `BOT_MODEL_GATE_*`, and `BOT_EVENT_VERIFY_FAIL` payloads.
- No cross-repo doc or shared ABI maps inference token statuses, digest mismatch, capacity underflow, or secure-local gate failures to TempleOS event IDs and fail-stop behavior.

Impact: even after a TempleOS token intake API exists, ambiguity remains about whether a blocked token event is a normal rejected tuple, a trusted-session abort, a `BOT_EVENT_VERIFY_FAIL`, or a hard stop under Law 9.

### INFO-001: existing model lifecycle gates are a good anchor for the missing ABI

Evidence:
- TempleOS already models secure-local gates for import, parse, deterministic parity, build attestation, verify, and promotion in `Kernel/BookOfTruth.HC`.
- holyc-inference already includes the fields needed for an inference-token trust tuple: session id, step index, token id, Q16 logit, policy digest, expected policy digest, profile mode, count, status, and event digest.

Impact: the drift can be closed without adding networking or non-HolyC runtime code by defining a local HolyC function such as `BookTruthInferenceTokenEvent(...)` and making holyc-inference target that ABI.

## Recommended Remediation

1. Add a TempleOS work item for a local HolyC token-event ingestion API in `Kernel/BookOfTruth.HC` and `Kernel/KExts.HC`.
2. Define a compact event schema with fixed fields: session id, step index, token id, logit Q16, policy digest, expected digest, profile mode, event status, and event digest.
3. Specify fail-closed behavior: in secure-local mode, policy-digest mismatch or append failure must block the trusted session, and append failure must follow Law 9 fail-stop semantics.
4. Update holyc-inference WS8/WS16 task language so "emit" means either "staged worker tuple only" or "TempleOS ledger append completed"; avoid using one word for both phases.
5. Add a Sanhedrin check that flags completed `InferenceBookOfTruthTokenEvent...` chains unless TempleOS exports a matching `BookTruth...Token...` ABI.

## Checks Performed

- `rg -n "Token|token|InferenceBook|BookTruth.*Token|BOT.*TOKEN|TOKEN|prompt|logit|policy_digest|BookTruthModel" /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/KExts.HC /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md`
- `rg -n "InferenceBookOfTruthTokenEvent|token_id|logit_q16|policy_digest_q64|profile_mode|event_digest_q64|Book.*Truth" /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/inference.HC /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_iq1791_bot_emit.py /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md`
- `sed -n '13280,13735p' /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC`
- `sed -n '3910,3925p' /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md`

## Verdict

Record as 3 warning findings and 1 positive anchor. The issue is cross-repo contract drift, not an immediate source-code violation: holyc-inference has useful local tuple machinery, but TempleOS does not yet expose the local, synchronous, fail-closed ledger ABI needed to make those token events Book-of-Truth records.
