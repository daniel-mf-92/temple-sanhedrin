# Cross-Repo Audit: Model Trust Manifest Proof-Tuple Drift

Timestamp: 2026-04-30T00:10:09+02:00

Audit angle: cross-repo invariant check for whether TempleOS model quarantine/trust decisions match the holyc-inference trusted-model manifest and quarantine proof tuple.

Repos reviewed:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `d84df3da3e8c241f43882f76493e1ae5a2f03b9e`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `485af0ea41a239c8393542d6e0e2fc5944f30f53`
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit` at `08cff2d03bbb57a16c898e3c60af74cc28a466c3`

No TempleOS or holyc-inference source file was modified. No QEMU, VM, WS8 networking, networking, or package-download command was executed.

## Expected Cross-Repo Invariant

`secure-local` model promotion should have one shared proof tuple that both repos can verify:

`{model_id, relative_path, full_sha256, size_bytes, quant_type, tokenizer_hash, provenance, parser_gate_status, attestation_or_policy_epoch, Book-of-Truth append proof}`

TempleOS is the trust/control plane and Book-of-Truth source of truth, while holyc-inference is the untrusted worker plane. Therefore worker-side SHA256 or quarantine success is only admissible after TempleOS can bind the exact same tuple to an immediate Book-of-Truth event.

Finding count: 5 findings: 1 critical, 4 warnings.

## Findings

### CRITICAL-001: TempleOS model trust APIs expose a logging bypass flag

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- `TempleOS/Kernel/BookOfTruth.HC:12644-12646` exposes `BookTruthModelImport(..., Bool emit_event=TRUE)`.
- `TempleOS/Kernel/BookOfTruth.HC:12737-12738` exposes `BookTruthModelVerify(..., Bool emit_event=TRUE)`.
- `TempleOS/Kernel/BookOfTruth.HC:12782` exposes `BookTruthModelPromote(I64 model_id, Bool emit_event=TRUE)`.
- `TempleOS/Kernel/KExts.HC:105-113` exports those APIs to callers with the same optional event parameter.

Assessment:
The default is logging-on, but Law 3 bans any config/API path that can disable Book-of-Truth logging. A caller can pass `FALSE` and perform import, verify, or promotion state changes without the corresponding Book-of-Truth append. This is especially severe because TempleOS is supposed to be the trust/control plane for quarantine and promotion.

Required remediation:
- Remove caller control over model trust logging in `secure-local`; model import, verify, parse, and promote should always append.
- If a non-logging dry-run is needed, expose it as a status-only function that cannot mutate model trust state.
- Sanhedrin should treat any trusted model state transition without an append proof as invalid evidence.

### WARNING-001: Full SHA256 identity is not shared across the trust boundary

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 5: North Star Discipline

Evidence:
- TempleOS policy requires `model_id`, `sha256`, quant type, tokenizer hash, and provenance in the trusted manifest (`MODERNIZATION/MASTER_TASKS.md:260-261`).
- TempleOS implementation stores and verifies only `sha_hi` and `sha_lo` (`Kernel/BookOfTruth.HC:12598-12621`, `12644-12691`, `12737-12779`), which is a 128-bit projection rather than the 64-hex-character SHA256 value.
- holyc-inference manifest parsing requires a 64-character SHA256 hex string (`src/model/trust_manifest.HC:24-35`, `291`, `745-805`) and its Python contract mirror verifies full `hashlib.sha256(model_bytes).hexdigest()` (`tests/test_model_trust_manifest_sha256.py:160-165`).

Assessment:
The repos do not currently share a single model digest representation. holyc-inference proves a full SHA256 over bytes, while TempleOS accepts two 64-bit lanes. Without a specified truncation/endian rule and collision policy, Sanhedrin cannot prove that a TempleOS trusted record refers to the same model bytes that holyc-inference verified.

Required remediation:
- Define a shared full-SHA256 representation for TempleOS records, or explicitly document a truncation rule plus why it is acceptable.
- Include the exact 64-hex-character digest in Book-of-Truth model status or append payload evidence.

### WARNING-002: holyc-inference manifest omits fields TempleOS says are mandatory

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- TempleOS trusted manifest schema requires `model_id`, `sha256`, quant type, tokenizer hash, and provenance (`MODERNIZATION/MASTER_TASKS.md:260-261`).
- holyc-inference trusted manifest line format is only `<sha256_hex_64> <size_bytes_decimal> <relative_model_path>` (`src/model/trust_manifest.HC:4-8`).
- holyc-inference quarantine state stores relative path, model size, manifest entry index, verified hash, and profile id, but no `model_id`, quant type, tokenizer hash, or provenance field (`src/model/quarantine.HC:31-40`, `366-426`).

Assessment:
The worker-side manifest proves byte identity and size, but not the full TempleOS trust schema. A model can pass holyc-inference WS16-03/WS16-02 while still lacking fields that TempleOS policy says are mandatory for trusted promotion.

Required remediation:
- Extend the worker manifest or add a second shared record so `model_id`, quant type, tokenizer hash, provenance, relative path, size, and full SHA256 cross together atomically.
- Gate `secure-local` promotion on that full tuple, not just hash+size success.

### WARNING-003: TempleOS promotion can pass without a parser-gate execution record

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- TempleOS promotion only fails parser status if `parse_fmt != 0 && !parse_ok` (`Kernel/BookOfTruth.HC:12808-12813`).
- A newly imported and verified model has `parse_fmt=0` and `parse_ok=1` by default (`Kernel/BookOfTruth.HC:12667-12670`).
- holyc-inference WS16 requires parser hardening before trusted-load eligibility (`MASTER_TASKS.md:211-212`).

Assessment:
TempleOS treats "parser not run" differently from "parser failed." That allows promotion evidence to omit the parser gate entirely, while holyc-inference policy says parser negative-corpus/fuzz pass is part of the secure-local trust chain.

Required remediation:
- Add an explicit parser-gate-required bit for `secure-local`, with `parse_fmt==0` treated as missing evidence rather than success.
- Bind parser gate status to the same model trust proof tuple as SHA256 and quarantine state.

### WARNING-004: Worker quarantine promotion is not Book-of-Truth anchored

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- holyc-inference quarantine promotes after secure profile check and verified state (`src/model/quarantine.HC:429-460` and subsequent state update), but the reviewed worker state carries no TempleOS `seq`, `entry_hash`, event marker, or append proof.
- TempleOS Book-of-Truth model flows append generic `BOT_EVENT_NOTE` / `BOT_EVENT_VERIFY_FAIL` events with compact payload markers (`Kernel/BookOfTruth.HC:12675-12685`, `12764-12773`, `12816-12843`).
- holyc-inference mission requires every model/trust-relevant inference path to be Book-of-Truth loggable (`MASTER_TASKS.md:23-30`).

Assessment:
Worker quarantine success is local evidence, not canonical trust evidence. Conversely, TempleOS compact payloads are not enough to reconstruct the worker's relative path, full SHA256, and size. The cross-repo proof is split across two systems without a join key.

Required remediation:
- Have TempleOS emit or return an append proof tuple for model import, verify, parser gate, and promote.
- Require holyc-inference trusted load to carry that append proof or remain classified as worker-local preflight evidence.

## Non-Findings

- No air-gap violation was found in the reviewed files. No networking or QEMU command was executed.
- holyc-inference trusted-model code is HolyC in core paths; the Python file reviewed is in `tests/`, which LAWS.md allows.
- holyc-inference SHA256 code is integer/bitwise arithmetic and does not introduce runtime floating-point math.

## Suggested Sanhedrin Follow-Up

Track a shared `ModelTrustProof` contract. Minimum fields: `model_id`, `rel_path`, `sha256_hex64`, `size_bytes`, `quant_type`, `tokenizer_hash`, `provenance`, `parser_gate_id`, `profile`, `bot_seq`, `bot_event_type`, `bot_payload_marker`, `bot_entry_hash`. Treat any missing field as warning evidence; treat model trust mutation with caller-disabled Book-of-Truth append as critical.

## Evidence Commands

- `git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD`
- `git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '30,55p;250,282p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC | sed -n '12480,12940p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/KExts.HC | rg -n "Model|Quarantine|Trust|BookTruthModel" -C 3`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/trust_manifest.HC | sed -n '1,260p;520,860p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/quarantine.HC | sed -n '1,460p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_model_trust_manifest_sha256.py | sed -n '1,260p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md | sed -n '1,70p;190,230p;1140,1175p'`
