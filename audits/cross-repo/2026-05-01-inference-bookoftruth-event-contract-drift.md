# Cross-Repo Audit: Inference Book-of-Truth Event Contract Drift

Timestamp: 2026-05-01T13:50:15+02:00

Scope: cross-repo invariant check between TempleOS current head `9f3abbf2` and holyc-inference current head `2799283c`.

Angle: Does what holyc-inference assumes about Book-of-Truth logging match the current TempleOS Book-of-Truth event, payload, profile, and policy surfaces?

Rules checked: Law 1, Law 2, Law 3, Law 4, Law 8, Law 9, Law 11, Trinity policy parity.

## Summary

The repos agree on the broad doctrine: HolyC-only runtime, air-gapped operation, `secure-local` as the hardened profile, and Book-of-Truth as the audit substrate. They do not yet agree on a concrete inference-event ABI. holyc-inference now has local tuple builders for token and policy/audit events, but TempleOS currently exposes a seven-field ledger entry with fixed event IDs and marker-packed payload families. No reviewed TempleOS surface accepts the inference tuple shape as a first-class event.

Findings: 5 warning findings, 0 critical findings.

## Findings

### WARNING 1: Per-token inference event tuple has no TempleOS ledger ABI

holyc-inference stages a six-cell per-token tuple `{session_id,step_index,token_id,logit_q16,policy_digest_q64,profile_mode}` and only copies it into a caller buffer when secure-local plus digest parity passes (`src/model/inference.HC:3371-3516`). TempleOS Book-of-Truth entries are seven ledger fields `{seq,tsc,event_type,source,payload,prev_hash,entry_hash}`, with all public append callers funneled through event IDs and one packed `payload` lane (`Kernel/BookOfTruth.HC:165-174`, `Kernel/BookOfTruth.HC:743`).

Impact: "every token logged to Book of Truth" is not currently an executable cross-repo contract. The inference runtime can prove an internal tuple was emitted, but there is no TempleOS-defined token payload marker, event ID, or adapter that can commit that tuple synchronously to the ledger under Law 8.

Expected invariant: TempleOS should define a canonical token payload encoder/decoder or first-class event type, and inference should target that exact ABI instead of a private six-cell staging tuple.

### WARNING 2: TempleOS event registry has no inference/token event family

TempleOS's current event namespace runs from `BOT_EVENT_INIT` through `BOT_EVENT_SERIAL_WATCHDOG` (`1..20`) and `BookTruthEventName` has no token, inference-call, tensor-op, model-load, or policy-digest event (`Kernel/BookOfTruth.HC:3-24`, `Kernel/BookOfTruth.HC:1956-1998`). Model provenance does exist, but it is encoded as marker payloads on `BOT_EVENT_NOTE` or `BOT_EVENT_VERIFY_FAIL`, not as an inference-token stream (`Kernel/BookOfTruth.HC:124-139`, `Kernel/BookOfTruth.HC:13474-13810`).

Impact: holyc-inference's North Star says the user gets a token with every token logged to the Book of Truth, but the TempleOS registry does not yet reserve a stable event family for that stream. This makes audit parsers likely to treat token rows as generic notes unless both sides converge on marker values and decoding rules.

Expected invariant: Reserve a TempleOS payload marker/event contract for inference call start, model load, token emit, tensor checkpoint, and anomaly rows before inference marks Book-of-Truth integration tasks complete.

### WARNING 3: `secure-default` bit semantics diverge between repos

TempleOS reports the default profile as `secure-local` regardless of current mode, while separately reporting the active profile (`Kernel/BookOfTruth.HC:13248-13255`). holyc-inference's `InferenceProfileStatusChecked` sets `out_is_secure_default` to whether the active profile is secure-local (`src/runtime/profile.HC:58-78`), then `InferencePolicyDigestChecked` describes bit 6 as the "secure-default flag" and mixes that active-mode-derived value into the policy digest (`src/runtime/policy_digest.HC:135-147`).

Impact: In `dev-local`, inference's policy digest will encode "secure-default=0" even though Trinity policy says `secure-local` remains the default and `dev-local` is only explicit opt-in. That can produce false Trinity drift or mask a real default-profile regression.

Expected invariant: Distinguish immutable default profile (`secure-local`) from active profile (`secure-local` or `dev-local`) in the inference digest tuple.

### WARNING 4: Policy digest guard tuple does not match TempleOS policy payload

holyc-inference policy digest bits cover IOMMU, Book-of-Truth DMA log, MMIO log, dispatch log, quarantine gate, hash manifest gate, secure-default flag, and active secure-local flag (`src/runtime/policy_digest.HC:27-33`, `src/runtime/policy_digest.HC:135-147`). TempleOS `BookTruthPolicyCheck` currently enforces and records W+X halt, tamper halt, serial mirror, IO log, disk log, and WX mode (`Kernel/BookOfTruth.HC:114-119`, `Kernel/BookOfTruth.HC:13269-13331`).

Impact: Both sides emit "policy" evidence, but the bit meanings are different. A Sanhedrin parity gate comparing digest/status outputs would be comparing unlike contracts unless it has a translation layer.

Expected invariant: Either TempleOS should publish a matching Trinity policy digest payload containing the inference guard tuple, or holyc-inference should name its digest as an inference-local guard digest and stop implying direct TempleOS Book-of-Truth parity.

### WARNING 5: GPU audit hooks assume dispatch/DMA/MMIO parity not exposed as one TempleOS gate

holyc-inference GPU policy requires IOMMU plus Book-of-Truth DMA, MMIO, and dispatch hooks (`src/gpu/security_perf_matrix.HC:4-7`, `src/gpu/security_perf_matrix.HC:60-66`). TempleOS has DMA payload encoding and `BookTruthDMARecord`, but DMA is recorded as `BOT_EVENT_NOTE` with the `BOT_DMA_PAYLOAD_MARKER`, and reviewed policy status does not fold DMA/MMIO/dispatch readiness into the same gate tuple (`Kernel/BookOfTruth.HC:41-45`, `Kernel/BookOfTruth.HC:761-768`, `Kernel/BookOfTruth.HC:82521-82631`, `Kernel/BookOfTruth.HC:13269-13331`).

Impact: Inference can pass a local GPU "Book guard" while TempleOS has no single current-head status line proving the exact same `{iommu,dma,mmio,dispatch}` tuple. This is a drift risk for WS9 GPU work and for Law 8 evidence that events are logged close to hardware.

Expected invariant: Define one TempleOS status/payload contract for GPU audit readiness, including IOMMU, DMA map/unmap, MMIO write, and dispatch transcript hooks, then make inference consume or reproduce that exact tuple.

## Non-Findings

- No networking implementation or VM command was added or executed during this audit.
- No TempleOS or holyc-inference source files were modified.
- Reviewed core runtime files remain HolyC source; host-side Python/bash remains confined to tooling/tests.
- The profile numeric IDs align at `1=secure-local`, `2=dev-local` across both repos.

## Recommended Follow-Up

Open a dedicated Trinity contract issue for a shared `BOT_INFERENCE_*` ABI with:

- TempleOS-owned event or payload marker constants.
- Encoder/decoder layout for token rows and policy digest rows.
- Explicit source ID for inference runtime rows, or a documented reuse of `BOT_SOURCE_CLI`/`BOT_SOURCE_KERNEL`.
- One parity test that reads both repos and fails if tuple width, marker values, or policy bit names diverge.
