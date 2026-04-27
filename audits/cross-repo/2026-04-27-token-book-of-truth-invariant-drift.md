# Cross-Repo Invariant Audit: Token Book-of-Truth Drift

Scope: retroactive / historical cross-repo audit only. No TempleOS or holyc-inference source was modified.

Repos inspected:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference`
- Sanhedrin audit branch: `codex/sanhedrin-gpt55-audit`

Audit angle: whether holyc-inference per-token "Book-of-Truth" work matches the TempleOS WS13 Book-of-Truth contract and the trinity split-plane policy.

## Finding CRITICAL-001: Inference token "Book-of-Truth emission" is a worker-plane tuple buffer, not a TempleOS WS13 append

Applicable laws:
- Law 3: Book of Truth immutability
- Law 8: Book of Truth immediacy and hardware proximity
- Law 9: crash on log failure
- Law 11: local access only

Evidence:
- `holyc-inference/MASTER_TASKS.md:8-10` says the target is `Inference("What is truth?");` with every token logged to the Book of Truth.
- `holyc-inference/MASTER_TASKS.md:23-24` says every inference call, token, and tensor checkpoint is loggable by the Book of Truth ledger.
- `holyc-inference/MASTER_TASKS.md:3906-3909` marks IQ-1791 through IQ-1794 done as per-token Book-of-Truth event emitters.
- `holyc-inference/src/model/inference.HC:3371-3516` implements `BotTokenEmitChecked`: it stages `{session_id,step_index,token_id,logit_q16,policy_digest_q64,profile_mode}`, sets `INFERENCE_BOT_STATUS_EMITTED`, copies six cells to caller memory, and returns digest/count/status.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:41-48` says TempleOS remains the trust/control plane and the inference runtime remains an untrusted worker plane.
- `LAWS.md:96-119` requires hardware-proximate synchronous Book-of-Truth recording, raw UART proximity, no queued/buffered decoupling, and no bypassable layer.
- `LAWS.md:123-139` requires the OS to die before the log dies.

Assessment:
The inference helper can return "emitted" without proving that a TempleOS `BookTruthAppend` happened, without serial `out 0x3F8`, without sealed-log integration, and without fail-stop behavior if the ledger cannot record. That is acceptable as a worker-plane preflight tuple, but it is not safe to call it Book-of-Truth emission under the current LAWS.md semantics.

Risk:
A future integration can wire `BotTokenEmitChecked` status into "token logged" accounting and believe secure-local token logging is satisfied while tokens never reach the TempleOS Book of Truth. That would move trust evidence into the worker plane and weaken the WS13 audit trail.

Required remediation:
- Rename or document the current inference functions as token audit tuple/preflight emitters until backed by TempleOS WS13 append semantics.
- Add a cross-repo ABI for token events: event type, source, payload layout, policy digest, and failure behavior.
- Gate any "every token logged" claim on a TempleOS-side append path that proves synchronous local Book-of-Truth recording and fail-closed behavior.

## Finding WARNING-001: TempleOS Book-of-Truth event vocabulary has no token/inference event ABI yet

Evidence:
- `TempleOS/Kernel/BookOfTruth.HC:3-22` defines events from `BOT_EVENT_INIT` through `BOT_EVENT_SERIAL_WATCHDOG`; no token, model-load, inference-call, tensor-checkpoint, policy-digest, or worker-attestation event appears in the event enum.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:259-280` still lists WS14 hardening tasks for profile state, model quarantine, attestation verifier, policy-digest handshake, and key-release gate as unchecked.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:264-278` includes WS14-06, WS14-18, WS14-19, and WS14-20 as future work, while holyc-inference already marks IQ-1791 through IQ-1794 done against WS8-03/WS16-06.

Assessment:
The worker repo has advanced token-event helper tasks faster than TempleOS has defined the corresponding Book-of-Truth event vocabulary. This is not a source-code violation by itself, but it is drift: the worker plane now has "done" Book-of-Truth token emitters without a TempleOS token-event contract to bind them to the control plane.

Risk:
Sanhedrin and builder agents may count inference-side tuple emission as WS13 progress even though TempleOS cannot classify or verify those rows as token events.

Required remediation:
- Add a TempleOS-side WS14/WS13 task for token/inference event IDs and payload schema before more inference "Book-of-Truth token" wrappers are marked complete.
- Add a Sanhedrin invariant check that flags worker-plane `INFERENCE_BOT_STATUS_EMITTED` as insufficient unless paired with a TempleOS event ABI and append path.

## Non-Findings

- Air-gap policy remains aligned in the inspected docs: TempleOS and holyc-inference both state no guest networking / disk-only model loading, and the trinity policy sync gate passed 21 checks.
- The inspected inference implementation is HolyC and integer-only in the audited path; the issue is semantic drift, not language purity.

## Commands Run

- `bash automation/check-trinity-policy-sync.sh` in holyc-inference: pass, 21 checks.
- `rg -n "InferenceBookOfTruthTokenEventEmit|BookOfTruthToken|BOT|book_of_truth|event_buffer|event_count|event_digest" ...`
- `rg -n "TOKEN|Token|MODEL|Model|INFERENCE|Inference|LLM|BOT_EVENT" Kernel/BookOfTruth.HC MODERNIZATION/MASTER_TASKS.md`
- `git log -S 'BotTokenEmitChecked' --format='%H %ad %s' --date=iso-strict -- src/model/inference.HC`
