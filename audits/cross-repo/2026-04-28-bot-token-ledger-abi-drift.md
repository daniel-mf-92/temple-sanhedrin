# Cross-Repo Audit: Book-of-Truth Token Ledger ABI Drift

Timestamp: 2026-04-28T14:57:21+02:00

Scope: retroactive cross-repo invariant check across TempleOS and holyc-inference. This audit did not run QEMU, did not touch trinity source code, and did not inspect live liveness state.

## Invariant Under Audit

`secure-local` inference must be air-gapped, HolyC-only, and logged through TempleOS as the sovereign Book-of-Truth control plane. holyc-inference may stage worker-plane token diagnostics, but the canonical ledger event/source namespace and the actual immutable append path must remain TempleOS-owned.

## Evidence Reviewed

- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC:3` defines canonical event IDs only through `BOT_EVENT_SERIAL_WATCHDOG = 20`; no model-load, token, inference-gate, profile-promotion, or worker-attestation event ID exists.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC:79` defines canonical sources only through `BOT_SOURCE_DISK = 7`; no inference worker, model loader, tokenizer, sampler, GPU worker, or trusted-load source exists.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:43` assigns policy, quarantine/promotion authority, key-release, and Book-of-Truth source-of-truth ownership to TempleOS.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:265` leaves `WS14-07 Add Book of Truth events for profile changes, model promotions, and gate failures` unchecked.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md:9` states the target response has every token logged to the Book of Truth, and `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md:115` leaves `WS8-03 Book of Truth integration hooks` unchecked.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/inference.HC:3374` documents a staged token tuple `{session_id,step_index,token_id,logit_q16,policy_digest_q64,profile_mode}` and `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/inference.HC:3445` publishes those six lanes to a caller buffer on emitted status.

## Findings

1. WARNING: TempleOS has no canonical inference/token event IDs for holyc-inference token diagnostics.
   - Evidence: TempleOS `BOT_EVENT_*` ends at serial watchdog (`20`) with no token/model/profile/gate events, while inference now has token event tuple helpers.
   - Impact: Any future bridge must invent event IDs out of band or overload existing events, weakening Law 8 hardware-proximate audit semantics and making Sanhedrin parsing ambiguous.
   - Required closure: Define TempleOS-owned `BOT_EVENT_MODEL_LOAD`, `BOT_EVENT_TOKEN_EMIT`, `BOT_EVENT_INFERENCE_GATE_FAIL`, `BOT_EVENT_PROFILE_CHANGE`, and related event IDs before any secure-local token logging is considered complete.

2. WARNING: TempleOS has no canonical source ID for inference/worker-plane events.
   - Evidence: `BOT_SOURCE_MASK_ALL` covers sources 1..7 only; source analyzers treat out-of-range values as unknown. holyc-inference has no matching source constant.
   - Impact: Token events bridged with an ad hoc source would either appear as `kernel`/`CLI`/`disk` or be counted as unknown source in TempleOS trend/reporting logic.
   - Required closure: Reserve TempleOS-owned source IDs for `INFERENCE`, `MODEL_LOADER`, `SAMPLER`, and optionally `GPU_WORKER`, then mirror constants into holyc-inference only as ABI consumers.

3. WARNING: holyc-inference `BotTokenEmit*` helpers produce a staged tuple, not a Book-of-Truth append.
   - Evidence: `BotTokenEmitChecked` writes only caller-provided `event_buffer` and output counters; reviewed lines show no call to TempleOS `BookTruthAppend` and no canonical `event_type/source/payload` construction.
   - Impact: The name and `INFERENCE_BOT_STATUS_EMITTED` status can be mistaken for ledger persistence, but Law 8 requires synchronous hardware-near append through TempleOS.
   - Required closure: Rename/spec the helper as staging unless/until a TempleOS-owned append bridge exists; Sanhedrin should reject claims of "token logged" based only on `event_buffer` publication.

4. WARNING: The token tuple cannot prove model quarantine/hash identity.
   - Evidence: The tuple lanes include `session_id`, `step_index`, `token_id`, `logit_q16`, `policy_digest_q64`, and `profile_mode`, but no `model_id`, `model_sha256`, tokenizer hash, manifest row, quarantine promotion ID, or attestation evidence reference.
   - Impact: A token log could prove that a token was staged under a profile/digest, but not which quarantined model artifact produced it. That drifts from TempleOS WS14-02/03 and inference WS16-02/03 trust manifest requirements.
   - Required closure: Bind token events to a prior TempleOS ledgered trusted-load event by compact session ID plus manifest hash, and make Sanhedrin able to join token events back to model promotion evidence.

5. WARNING: Preflight and replay helpers preserve caller buffers, but there is no cross-repo parser contract to distinguish staged/preflight diagnostics from real ledger facts.
   - Evidence: `BotTokenEmitDiagReplayCommitPreflight` explicitly preserves caller event/output slots on success, while `BotTokenEmitChecked` can return `INFERENCE_BOT_STATUS_EMITTED` for staged data. TempleOS has no corresponding parser or status vocabulary.
   - Impact: Test-only or preflight evidence could be misread as durable Book-of-Truth evidence in future reports.
   - Required closure: Add an ABI document that separates `preflight`, `staged`, `committed-to-TempleOS`, and `sealed` states, with TempleOS as the only authority for committed/sealed states.

## Law Assessment

- Law 1: No new non-HolyC core implementation detected in this audit scope.
- Law 2: No networking commands or guest networking changes were executed.
- Law 3 / Law 8: No direct source violation found, but the current token-ledger ABI is incomplete for secure-local claims because the actual TempleOS append/event/source contract is missing.
- Law 5: The inference-side token diagnostics are meaningful, but must not be counted as secure-local Book-of-Truth completion until TempleOS canonical events and append integration exist.

## Recommended Sanhedrin Checks

- Block any claim that "every token is logged to Book of Truth" unless a TempleOS `BOT_EVENT_TOKEN_*` event exists and a reviewed path calls the TempleOS append primitive.
- Flag any inference token event tuple that lacks a join key to a TempleOS model-promotion/trusted-load ledger event.
- Treat out-of-range Book-of-Truth sources for inference/token events as cross-repo ABI drift, not just a reporting nuisance.
