# Cross-Repo Audit: Token Event Symbol/Wiring Drift

Timestamp: 2026-05-02T11:31:41+02:00

Scope: read-only cross-repo invariant check across `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` and `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference`.

Audited heads:
- TempleOS: `9f3abbf263982bf9344f8973a52f845f1f48d109` (`feat(modernization): codex iteration 20260501-111528`, 2026-05-01T11:26:42+02:00)
- holyc-inference: `2799283c9554bea44c132137c590f02034c8f726` (`feat(inference): codex iteration 20260430-025722`, 2026-04-30T03:00:56+02:00)
- Sanhedrin audit branch before this report: `08395f3357afcd1cfdbb1cd28980bc1d6000bf7f`

No TempleOS or holyc-inference source files were modified. No QEMU, VM, live liveness watching, process restart, WS8 networking task, NIC, socket, TCP/IP, UDP, DNS, DHCP, HTTP, TLS, package-manager, or remote runtime action was executed. The TempleOS guest air-gap was not touched.

## Invariant Under Audit

holyc-inference claims WS8-03/WS16-06 progress for per-token Book-of-Truth emission. TempleOS is the sovereign Book-of-Truth control plane. For that to be an executable cross-repo invariant, the current heads need all of these to agree:

1. holyc-inference task text, HolyC symbol names, and tests should refer to the same public token-event API.
2. generated-token paths should call that API for each emitted token when secure-local evidence is required.
3. TempleOS should expose a matching Book-of-Truth token event sink, source ID, payload marker, or decode/status command.
4. any "emitted" status must mean TempleOS append/serial/fail-stop succeeded, not only that a worker-local buffer was populated.

## Findings

### WARNING 1. holyc-inference task text names `InferenceBookOfTruthTokenEventEmitChecked`, but the source implements `BotTokenEmitChecked`

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md:3916` marks IQ-1791 done as HolyC `InferenceBookOfTruthTokenEventEmitChecked`.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/inference.HC:3371` through `3379` describe the per-token Book-of-Truth gate, then define `I32 BotTokenEmitChecked(...)`.
- Searching current `src/model/inference.HC`, `tests`, and `MASTER_TASKS.md` found no `I32 InferenceBookOfTruthTokenEventEmitChecked` implementation.

Impact: automated cross-repo checks that key off the claimed public symbol will not find the implementation. More importantly, the shorter `BotTokenEmitChecked` name reads as a local staging helper, while the task text implies an inference-facing Book-of-Truth API.

### WARNING 2. The token generator commits sampled tokens without calling the Book-of-Truth event helper

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/inference.HC:3318` through `3366` loops over `max_new_tokens`, calls `GenerationStepChecked`, commits `sampled_token_id` to history/output buffers, and increments `out_generated_count`.
- The same inspected loop has no call to `BotTokenEmitChecked` or any `InferenceBookOfTruth*` helper before or after the token commit.
- `BotTokenEmitChecked` starts after the generation helper, at `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/inference.HC:3379`, which makes it adjacent code rather than wired generation-path behavior.

Impact: holyc-inference can mark per-token event helpers complete while generated-token production remains independent of Book-of-Truth emission. Under Law 5/North Star Discipline, helper existence is not enough for "every token logged" progress unless the generation path invokes it or a named integration task remains open.

### WARNING 3. "Emitted" currently means worker-local tuple publication, not TempleOS ledger append

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/inference.HC:3445` through `3450` stages a six-lane tuple `{session_id, step_index, token_id, logit_q16, policy_digest_q64, profile_mode}`.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/inference.HC:3452` through `3461` sets `INFERENCE_BOT_STATUS_EMITTED` when `profile_mode` is secure and the policy digest matches.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/inference.HC:3507` through `3515` only copies that tuple into caller memory and publishes status/count/digest.
- No TempleOS `BookTruthAppend`, serial mirror, or fail-stop result is part of this helper's status domain.

Impact: a secure-local digest match can produce an "emitted" status even though no current TempleOS append path was involved. That is worker-plane evidence, not Book-of-Truth evidence under Laws 3, 8, and 9.

### WARNING 4. TempleOS has no token/inference event family for the tuple to target

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC:3` through `22` define the current canonical event range from `BOT_EVENT_INIT` through `BOT_EVENT_SERIAL_WATCHDOG`; there is no token or inference event ID.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC:141` through `148` define source IDs through `BOT_SOURCE_DISK`; there is no `BOT_SOURCE_INFERENCE` or worker-plane source.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC:82493` through `82521` expose a DMA append helper that encodes a DMA payload and appends it as `BOT_EVENT_NOTE`, but there is no equivalent token-event append/decode path.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/KExts.HC:113` through `142` exports model gate and DMA helpers, but no token-event helper.

Impact: even if holyc-inference called its helper on every token, current TempleOS would still lack a first-class ingestion target for the six-lane token tuple. Sanhedrin cannot verify token rows as canonical Book-of-Truth rows without a shared event/source/payload contract.

### WARNING 5. TempleOS policy/task state still says the trust boundary is not fully wired

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:33` through `36` require secure-local to be air-gapped, Book-of-Truth always-on, and GPU gated by IOMMU plus Book-of-Truth hooks.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:275` through `278` still leave the control-plane vs worker-plane contract, attestation verifier, policy-digest handshake, and key-release gate unchecked.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:27` names `Inference("prompt");` as a CLI goal, but current inspected TempleOS exports do not include a token-event ingress ABI for that path.

Impact: worker-side token event helpers should remain classified as pre-ledger staging until TempleOS completes the control-plane contract and exposes a Book-of-Truth token append/decode surface. Treating IQ-1791..1799 as secure-local token logging completion would overstate cross-repo readiness.

## Recommended Closure

- Align holyc-inference task text, symbols, and tests on one public API name, preferably `InferenceBookOfTruthTokenEventEmitChecked` if that is the intended contract.
- Keep `BotTokenEmitChecked` if desired, but mark it as worker-local staging and add a separate integration task for generation-loop wiring.
- Add a TempleOS-owned `BOT_EVENT_INFERENCE_TOKEN` or payload-marker contract with source ID, encoder/decoder, serial output shape, and fail-stop behavior.
- Require generated-token paths to call the token event API before reporting secure-local token success.
- Make `INFERENCE_BOT_STATUS_EMITTED` mean TempleOS ledger append acknowledged, or rename it to `STAGED` until a TempleOS append path exists.

Finding count: 5

## Read-Only Commands Used

```sh
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS log -1 --format='%h %cI %s'
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference log -1 --format='%h %cI %s'
rg -n "I32 InferenceBookOfTruthTokenEventEmitChecked|InferenceBookOfTruthTokenEventEmitChecked\\(" src/model/inference.HC tests MASTER_TASKS.md
rg -n "I32 BotTokenEmitChecked|BotTokenEmitChecked\\(" src/model/inference.HC tests MASTER_TASKS.md
rg -n "BookTruth.*Token|Token.*BookTruth|BOT_.*TOKEN|INFERENCE_BOT|BOT_SOURCE_(INFERENCE|WORKER)|BookTruth.*Inference|Inference.*BookTruth" Kernel/BookOfTruth.HC Kernel/KExts.HC MODERNIZATION/MASTER_TASKS.md automation
nl -ba src/model/inference.HC | sed -n '20,35p;3208,3379p;3379,3520p'
nl -ba MASTER_TASKS.md | sed -n '3910,3925p'
nl -ba Kernel/BookOfTruth.HC | sed -n '1,25p;136,150p;82490,82525p'
nl -ba Kernel/KExts.HC | sed -n '108,142p'
nl -ba MODERNIZATION/MASTER_TASKS.md | sed -n '24,36p;260,279p'
```
