# Cross-Repo Audit: Prompt Tokenization Entrypoint Drift

Timestamp: 2026-05-02T11:58:28+02:00

Scope: read-only cross-repo invariant check across `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` and `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference`.

Audited heads:
- TempleOS: `9f3abbf263982bf9344f8973a52f845f1f48d109` (`feat(modernization): codex iteration 20260501-111528`, 2026-05-01T11:26:42+02:00)
- holyc-inference: `2799283c9554bea44c132137c590f02034c8f726` (`feat(inference): codex iteration 20260430-025722`, 2026-04-30T03:00:56+02:00)
- Sanhedrin audit branch before this report: `ad5c83eb1af23f86ee6eb0ceda379ce43066eba2`

No TempleOS or holyc-inference source files were modified. No QEMU, VM, live liveness watching, process restart, current-iteration compliance check, WS8 networking task, NIC, socket, TCP/IP, UDP, DNS, DHCP, HTTP, TLS, package-manager, remote runtime, or network action was executed. The TempleOS guest air-gap was not touched.

## Invariant Under Audit

TempleOS claims `Inference("prompt");` as a first-class CLI command, while holyc-inference owns the tokenizer and generation runtime. A working cross-repo contract needs all of these to be true:

1. TempleOS has a string-entry command contract that names byte encoding, bounds, failure behavior, and Book-of-Truth logging for the raw prompt.
2. holyc-inference has a callable path from prompt bytes through BPE token IDs into generation.
3. the fixed-token north-star path and the interactive string path share deterministic parity evidence, not separate success definitions.
4. prompt input and decoded token output are local-only and serial/console scoped, preserving Laws 2 and 11.

## Findings

### WARNING 1. TempleOS promises `Inference("prompt");` but exposes no current HolyC implementation

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:27` names `BookOfTruth;` and `Inference("prompt");` as CLI commands.
- A read-only search for `Inference(` under TempleOS `.HC`, `.HH`, `.PRJ`, and `.md` files found only that modernization task text.
- TempleOS `MASTER_TASKS.md:31` through `47` defines the secure-local control-plane role, but `WS14-17` through `WS14-20` remain unchecked for command surface, attestation verifier, policy digest handshake, and key-release gate.

Impact: the control plane has a CLI obligation but no visible ABI for prompt bytes, tokenized prompt IDs, tokenizer errors, or Book-of-Truth event ordering. holyc-inference can keep advancing tokenizer helpers without a TempleOS-owned entrypoint contract to satisfy.

### WARNING 2. holyc-inference's executable north star still bypasses text tokenization

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/NORTH_STAR.md:7` defines the concrete deliverable as one GPT-2 forward pass in HolyC inside TempleOS.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/NORTH_STAR.md:17` fixes the prompt as token ID sequence `[15496, 11, 995]`, not as the source string passing through the tokenizer.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md:9` through `10` define the user target as `Inference("What is truth?");` with every token logged to Book of Truth.

Impact: current success can be scored on a hand-provided token sequence while the user-facing string prompt path remains unproven. That is useful for model math, but it is not enough to close the TempleOS CLI contract.

### WARNING 3. tokenizer work exists, but the generation API still consumes token history directly

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/tokenizer/bpe.HC:4134` defines `TokenizerBPEEncodePromptChecked(...)`.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/inference.HC:3150` defines `InferenceGenerateTokensCheckedTopKTopPNoPartial(...)`.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/inference.HC:3220` through `3224` validate token history, logits, random values, workspaces, and generated-token outputs, but no prompt byte buffer or tokenizer table.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/inference.HC:3318` through `3366` generate sampled tokens from `token_history` and update token buffers directly.

Impact: there is no inspected public bridge from `U8 *prompt_bytes` to `token_history` to generated-token output. The tokenizer and generator can each pass local tests while the interactive `Inference("prompt");` path remains absent.

### WARNING 4. tokenizer base-token semantics are not tied to the model's vocabulary contract in the cross-repo policy

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/tokenizer/bpe.HC:2531` through `2548` builds the base pretokenization state as one token per byte before BPE merge passes.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/tokenizer/bpe.HC:2472` through `2477` accepts merge rank tables as caller-provided arrays, while `MASTER_TASKS.md:98` still lists the GGUF BPE vocabulary loader as unchecked.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md:97` through `102` keeps WS6 tokenizer load/encode/decode/special-token validation unchecked despite many completed helper-level IQ entries.

Impact: helper-level BPE progress is real, but the cross-repo invariant still lacks a stated source of truth for vocab/rank tables, byte fallback behavior, BOS/EOS policy, and llama.cpp parity at the TempleOS command boundary.

### WARNING 5. decoded text and prompt bytes lack a Law 11 local-access boundary

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md:202` allows an "OpenAI-compatible local API" only as CLI-based and serial-port accessible with no HTTP.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/tokenizer/bpe.HC:12294` through `12318` and `12403` onward define prompt decode capacity and decode wrappers that can materialize text bytes from token IDs.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:23` through `28` require full CLI/headless serial operation, but current inspected policy does not define whether inference prompt/output text is Book-of-Truth content, ordinary console output, or both.

Impact: once string prompts and decoded outputs are wired, they become sensitive local text. Without a TempleOS-owned local-only export rule for inference text, Law 11 can be preserved for Book-of-Truth rows while decoded LLM text leaks through a side channel.

## Recommended Closure

- Add a TempleOS-owned `Inference("prompt");` ABI note before implementation: encoding, max bytes, tokenizer source, BOS/EOS defaults, failure statuses, and Book-of-Truth event sequence.
- Add a holyc-inference integration wrapper that calls `TokenizerBPEEncodePromptChecked...` before `InferenceGenerateTokens...`, with no-partial failure behavior and deterministic prompt/token trace output.
- Extend the north-star evidence from fixed token IDs to a second mode that starts from `"Hello, world"` bytes and proves the same `[15496, 11, 995]` prompt tokens.
- Treat WS6 helper completions as staging until GGUF vocabulary/rank loading and llama.cpp tokenizer parity are wired into the public prompt path.
- Explicitly classify generated text and prompt bytes as local console/serial-only data, and forbid any remote export path under Law 11.

Finding count: 5

## Read-Only Commands Used

```sh
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS log -1 --format='%h %cI %s'
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference log -1 --format='%h %cI %s'
rg -n "Inference\\(" /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS -g '*.HC' -g '*.HH' -g '*.PRJ' -g '*.md' --glob '!automation/logs/**'
rg -n "TokenizerBPEEncodePromptChecked|GenerateTokens|token_ids|prompt_nbytes|prompt_tokens|input_tokens|Inference\\(" holyc-inference files
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/NORTH_STAR.md
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/tokenizer/bpe.HC
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/inference.HC
```
