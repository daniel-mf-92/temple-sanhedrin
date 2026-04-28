# Cross-Repo Prompt Token Policy Drift Audit

- Audit angle: cross-repo invariant checks
- Audit time: `2026-04-28T09:23:07+02:00`
- TempleOS HEAD inspected: `e868ba65878b282ff5b2d2464b6bd95cb56e6c76`
- holyc-inference HEAD inspected: `ce09228422dae06e86feb84925d51df88d67821b`
- Sanhedrin HEAD before this report: `66bb8ad7d8be530a8b203b848b3a246a39508b60`
- Scope: read-only review of prompt/token policy surfaces. No TempleOS or holyc-inference files were modified, and no QEMU or VM command was executed.

## Summary

The inference repo has moved beyond fixed token IDs: it now contains HolyC tokenizer code for UTF-8 validation, prompt-span scanning, BPE encode/decode capacity accounting, BOS/EOS/PAD metadata resolution, and no-alloc parity harnesses. TempleOS integration surfaces still describe `Inference("prompt");`, serial-only control, and Book-of-Truth logging, but they do not define the cross-repo prompt-token policy needed to connect guest CLI text to the inference token stream.

This is not an air-gap or HolyC-purity violation. It is a Law 5 / North Star Discipline drift: the repos can each advance locally while still disagreeing on the exact token sequence and metadata policy that must be logged and validated for a trusted run.

## Findings

### Finding WARNING-001: North-star prompt is a fixed token sequence, while integration goal is a text CLI prompt

Evidence:
- `holyc-inference/NORTH_STAR.md:15-18` defines the concrete run as fixed prompt token IDs `[15496, 11, 995]` for `"Hello, world"`.
- `holyc-inference/MASTER_TASKS.md:42-46` separately lists BPE tokenizer, interactive `Inference("prompt");`, benchmark, and llama.cpp parity as north-star outcomes.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:23-28` requires every user-facing feature to be CLI-first and explicitly lists `Inference("prompt");` as a serial-console command.

Impact:

A run can satisfy the current inference north star by injecting token IDs directly while skipping the guest-visible text-to-token path that TempleOS users will exercise. Conversely, TempleOS can expose a text CLI entry point without proving that the resulting token IDs are the exact IDs used by the reference benchmark.

Recommendation:

Define a shared prompt manifest containing both text bytes and canonical token IDs, for example `prompt_utf8_sha256`, `prompt_nbytes`, `tokenizer_family`, `token_ids`, and `special_token_policy`. Require serial telemetry to include the manifest digest and token count before the next-token result.

### Finding WARNING-002: Special-token policy exists in inference code but has no TempleOS-side invariant

Evidence:
- `holyc-inference/src/tokenizer/bpe.HC:83-155` resolves BOS/EOS/PAD from GGUF metadata keys with fallback and missing-token behavior.
- `holyc-inference/MASTER_TASKS.md:97-102` treats special tokens as a tokenizer workstream requirement.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:31-39` defines secure-local model loading and promotion policy, but no prompt-token invariant for BOS/EOS/PAD insertion, suppression, or logging.

Impact:

The same prompt text can produce different model inputs depending on whether BOS is prepended, EOS is appended, padding is allowed, or fallback IDs are accepted when metadata is missing. That undermines bit-exact reference parity and Book-of-Truth auditability because the ledger may record a prompt or output token without recording the hidden special-token policy that shaped the run.

Recommendation:

Add a cross-repo `prompt_token_policy` tuple to trusted inference evidence: `bos_id`, `eos_id`, `pad_id`, `has_bos`, `has_eos`, `has_pad`, `prepend_bos`, `append_eos`, `allow_missing_specials`, and `metadata_source_digest`.

### Finding WARNING-003: UTF-8 and span-scan contract is inference-local, not a TempleOS CLI contract

Evidence:
- `holyc-inference/src/tokenizer/bpe.HC:3435-3631` scans prompt bytes into ASCII/non-ASCII spans, validates UTF-8 continuation/codepoint paths, and stages output to avoid partial mutation.
- `holyc-inference/src/tokenizer/bpe.HC:3634-3679` derives default span capacity from `prompt_nbytes`.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:21-28` promises headless serial CLI operation but does not specify prompt byte encoding, maximum byte length, newline handling, or malformed-input behavior for `Inference("prompt");`.

Impact:

TempleOS text entry and inference tokenization can drift on byte boundaries. Examples: serial CRLF normalization, NUL bytes, high-bit bytes from DolDoc/text buffers, malformed UTF-8, and maximum prompt byte count. Any one of those changes token IDs while leaving user-visible text apparently unchanged.

Recommendation:

Declare the TempleOS inference CLI prompt input as a byte-exact UTF-8 contract: accepted bytes, maximum prompt bytes, CR/LF normalization, NUL rejection, malformed UTF-8 failure mode, and whether the Book of Truth logs raw prompt digest, normalized prompt digest, or both.

### Finding WARNING-004: No-alloc tokenizer capacity evidence is not yet carried into TempleOS resource/fail-stop policy

Evidence:
- `holyc-inference/src/tokenizer/bpe.HC:5180-5212` computes required token capacity and merge workspace bytes before delegating to the checked no-partial encoder.
- `holyc-inference/src/tokenizer/bpe.HC:5215-5264` derives default token capacity from `prompt_nbytes`.
- `holyc-inference/src/tokenizer/bpe.HC:6168-6193` checks that required token capacity equals `prompt_nbytes`, checks merge workspace bytes, and publishes required capacities atomically.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:43-47` says TempleOS secure-local is the trust/control plane and invalid evidence must fail closed, but it does not map tokenizer capacity failures to a trusted-run rejection or Book-of-Truth event.

Impact:

The inference tokenizer has capacity and no-partial semantics, but TempleOS policy does not yet say what happens when prompt tokenization needs more workspace than the secure-local budget allows. If that behavior is left implicit, builders may handle it as a recoverable UI error, a silent truncation risk, or a guest halt path inconsistently.

Recommendation:

Promote tokenizer capacity diagnostics into the trusted-run evidence envelope: `prompt_nbytes`, `required_token_capacity`, `required_merge_workspace_bytes`, `workspace_budget_bytes`, and `tokenization_status`. In secure-local, missing or non-OK status should reject the inference run and log the rejection locally.

### Finding WARNING-005: Current TempleOS north-star script still checks only Book-of-Truth demo lines

Evidence:
- `TempleOS/automation/north-star-e2e.sh:9-13` requires only `BoT: boot ok`, `BoT: keypress=q`, and `BoT: halt clean`.
- `TempleOS/automation/north-star-e2e.sh:20-26` boots QEMU with `-nic none` and serial capture, but does not attach the documented `shared.img` or check prompt/token evidence.
- `TempleOS/automation/qemu-holyc-load-test.sh:120-127` has a separate shared-image QEMU path with `-drive file="$SHARED_IMG",format=raw,if=ide`, `-nic none`, and serial capture.

Impact:

TempleOS has an air-gapped shared-image harness path, but the top-level north-star proof remains Book-of-Truth demo-only. That lets the control-plane proof and inference prompt-token proof remain separate even though the intended deliverable is an air-gapped guest running HolyC inference with every token logged.

Recommendation:

Keep the existing `BoT:` lines, but add an optional second phase or sibling gate that consumes the shared prompt manifest and requires a serial `INFERENCE_TOKEN_POLICY:` / `BENCH_RESULT:` record. Any QEMU path must continue to include `-nic none`; no WS8 networking work should be executed.

## Positive Observations

- Reviewed QEMU command surfaces keep explicit `-nic none` air-gap evidence.
- Tokenizer implementation and tests are HolyC core plus host-side Python validation, which matches the language policy boundary.
- The drift is contractual rather than a direct observed violation: no networking, socket, package-download, or non-HolyC core implementation was introduced by the reviewed surfaces.

## Safety Notes

- No TempleOS guest networking stack, NIC driver, socket, TCP/IP, UDP, TLS, DHCP, DNS, HTTP, or remote runtime service was added or enabled.
- No WS8 networking task was executed or recommended.
- No QEMU or VM command was executed during this audit.
- Recommendations preserve the air-gap and keep core TempleOS/inference implementation in HolyC.

## Commands Run

Read-only commands only:

```bash
git rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/NORTH_STAR.md | sed -n '1,30p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md | sed -n '36,116p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/tokenizer/bpe.HC | sed -n '1,260p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/tokenizer/bpe.HC | sed -n '3430,3725p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/tokenizer/bpe.HC | sed -n '5180,5325p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/tokenizer/bpe.HC | sed -n '6100,6215p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/NORTH_STAR.md | sed -n '1,40p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '21,48p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/north-star-e2e.sh | sed -n '1,80p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/qemu-holyc-load-test.sh | sed -n '90,150p'
rg -n "TokenizerBPE(EncodePrompt|DecodePrompt|SpecialTokens|PromptSpan|DecodeSingle|DecodeToken)|bos_token|eos_token|padding_token|special" /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/tokenizer/bpe.HC /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_tokenizer_* /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/NORTH_STAR.md
rg -n "Inference\\(|prompt|token|Book of Truth|secure-local|serial|shared.img|BPE|BOS|EOS|special" /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/NORTH_STAR.md /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/LOOP_PROMPT.md /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth*.HC /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/SerialDev/*.HC /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/north-star-e2e.sh /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/qemu-holyc-load-test.sh
```

Finding count: 5 warnings.
