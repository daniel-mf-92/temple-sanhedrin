# Cross-Repo Audit: Prompt/Token Ingress Boundary Drift

Timestamp: 2026-04-29T05:33:29+02:00

Audit owner: gpt-5.5 sibling, retroactive / historical scope only

Repos examined:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `abbc679bc7c429c0d89cdef04432b2e7a9d51fc7` (`feat(modernization): codex iteration 20260429-045038`)
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `ce09228422dae06e86feb84925d51df88d67821b` (`feat(inference): codex iteration 20260428-085506`)
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit`

Audit angle: cross-repo invariant check. No TempleOS or holyc-inference source code was modified. No QEMU, VM, liveness watcher, process restart, or WS8 networking task was executed.

## Summary

Found 5 findings: 4 warnings and 1 info.

Both repos point toward a local `Inference("prompt")` workflow, but they do not yet share a canonical prompt-ingress boundary. TempleOS' modernization plan names `Inference("prompt");` as a CLI command, while current TempleOS core source has no implemented inference command or BPE/UTF-8 tokenizer surface. holyc-inference has deep UTF-8/BPE encode/decode helpers and token-generation callback tuples, but those APIs operate on byte buffers, token IDs, vocab piece arrays, and callback ABI tuples. The missing contract is the bridge between a TempleOS CLI string, a validated UTF-8 prompt span, the resulting token-history window, and the local Book-of-Truth evidence that proves those exact bytes/tokens were the ones run.

This is not a current air-gap breach. It is a warning-level integration drift: if future builders connect the repos ad hoc, they can accidentally validate fixed token IDs while leaving interactive prompt bytes, tokenizer metadata, output decode, and Book-of-Truth prompt provenance outside the shared invariant.

## Finding WARNING-001: `Inference("prompt")` is specified in both plans, but not yet present as a TempleOS core command

Applicable laws:
- Law 5: North Star Discipline
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- TempleOS modernization requires CLI-first access and explicitly lists `Inference("prompt");` alongside `BookOfTruth;` and system diagnostics: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:21`.
- holyc-inference's mission target is a user typing `Inference("What is truth?");` inside TempleOS, with every token logged: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md:9`.
- holyc-inference tracks `Inference(prompt, max_tokens, temp, top_k, top_p);` and interactive streaming as future integration tasks: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md:109` and `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md:116`.
- A targeted read-only search over TempleOS `Kernel/`, `Adam/`, `Compiler/`, and `Apps/` found no `Inference(`, `TokenizerBPE`, `UTF8`, `UTF-8`, or `BPE` implementation surface.

Assessment:

The repos agree on the user-facing command name at the roadmap level, but the current TempleOS core does not yet own the command or its input validation. Until that exists, Sanhedrin cannot distinguish a real guest-local prompt execution from host-side fixed-token tests.

Recommended closure:

Define a TempleOS-owned `Inference` CLI ABI before implementation: input byte pointer, byte length, tokenizer profile/hash, seed/sampling fields, generated-token limit, and Book-of-Truth append proof fields.

## Finding WARNING-002: fixed-token north-star evidence can bypass prompt-byte validation

Applicable laws:
- Law 5: North Star Discipline
- Law 3: Book of Truth Immutability

Evidence:
- holyc-inference north star currently defines success as one forward pass on fixed token IDs `[15496, 11, 995]` for "Hello, world": `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/NORTH_STAR.md:7` and `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/NORTH_STAR.md:17`.
- The same repo also requires a BPE tokenizer in HolyC and validation that tokenize/detokenize round-trip matches llama.cpp: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md:97`.
- TempleOS modernization requires a deterministic inference gate with fixed prompt/seed/logit-window parity: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:263`.

Assessment:

The fixed token-ID path is a useful small north star, but it can become a false integration proof if it is treated as equivalent to `Inference("Hello, world")`. A true prompt path must prove exact prompt bytes, tokenizer metadata hash, BOS/EOS policy, token ID sequence, and final generated token provenance.

Recommended closure:

Add a cross-repo fixture that records both forms for the same prompt:
`prompt_bytes_hex`, `prompt_utf8_valid`, `tokenizer_hash`, `bos_eos_policy`, `token_ids`, `seed`, `sampling_params`, `next_token_id`, and a TempleOS ledger anchor.

## Finding WARNING-003: tokenizer special-token policy is inference-local, while TempleOS profile manifests only mention a tokenizer hash

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- TempleOS WS14 manifest schema currently lists `model_id`, `sha256`, quant type, tokenizer hash, and provenance: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:261`.
- holyc-inference resolves BOS/EOS/PAD metadata keys and fallback policy inside `TokenizerBPESpecialTokensResolveCheckedNoPartial`: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/tokenizer/bpe.HC:83`.
- That resolver accepts fallback IDs and an `allow_missing_without_fallback` policy: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/tokenizer/bpe.HC:83` through `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/tokenizer/bpe.HC:154`.

Assessment:

A tokenizer hash alone does not capture the runtime policy that decides whether BOS/EOS/PAD are injected, defaulted, or absent. If TempleOS approves only `tokenizer_hash`, holyc-inference can still produce different token histories for the same prompt under different special-token fallback policy.

Recommended closure:

Extend the trusted-model/policy manifest contract with explicit `bos_token_id`, `eos_token_id`, `pad_token_id`, `has_*` flags, and `allow_missing_special_tokens` or equivalent policy digest inputs.

## Finding WARNING-004: token stream callback ABI lacks prompt/session and TempleOS ledger anchors

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- holyc-inference token callback tuple contains only ABI version, flags, token index, token ID, and token probability/logit in Q16: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/inference.HC:1490`.
- The dispatcher stages and publishes that five-cell tuple after callback success: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/inference.HC:1503` through `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/inference.HC:1599`.
- TempleOS local-only Book-of-Truth policy requires log access to stay local and identifies the serial mirror as local host evidence only: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:222` through `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:230`.

Assessment:

The callback ABI is integer-only and conservative, but it cannot by itself prove which prompt/session/model produced the token, nor can it prove that TempleOS appended the token event to the immutable local ledger. It needs either a surrounding session tuple or direct append-proof fields.

Recommended closure:

Define token-event proof as `{session_id, prompt_hash, model_hash, tokenizer_hash, token_index, token_id, token_prob_q16, ledger_seq, ledger_entry_hash}`. The token callback can stay small, but secure-local evidence must include the larger proof tuple.

## Finding INFO-001: reviewed tokenizer and generation surfaces preserve HolyC/integer-only posture

Applicable laws:
- Law 1: HolyC Purity
- Law 4: Integer Purity
- Law 2: Air-Gap Sanctity

Evidence:
- holyc-inference tokenizer code is HolyC and uses `U8`, `U64`, `I32`, and `I64` byte/token buffers, not floating-point runtime tensor math: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/tokenizer/bpe.HC:1`.
- Prompt decode helpers validate cursor/capacity and consume token windows deterministically: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/tokenizer/bpe.HC:12854`.
- Generation diagnostics validate Q16 temperature/top-p/repetition parameters and integer capacities: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/inference.HC:1893`.
- No QEMU or VM command was run during this audit; no networking stack, NIC, socket, TCP/IP, UDP, DNS, DHCP, HTTP, or TLS surface was added or enabled.

Assessment:

The issue is not an immediate Law 1, Law 2, or Law 4 violation. It is the absence of a shared ingress/provenance contract around otherwise useful HolyC tokenizer and token-stream primitives.

## Recommended Backlog Items

- Add a shared prompt-ingress contract document owned by Sanhedrin or both repos: `prompt_bytes`, `byte_len`, UTF-8 validation status, tokenizer hash, special-token policy, token IDs, seed/sampling params, output token IDs, and ledger anchors.
- Require the north-star E2E to prove both `fixed_token_ids` and `prompt_bytes -> token_ids` for "Hello, world" before it is counted as interactive inference readiness.
- Treat `Inference("prompt")` as incomplete until TempleOS owns the CLI command and emits local Book-of-Truth prompt/session/token evidence.
- Keep WS15 API compatibility explicitly CLI/local only; do not convert the prompt-ingress bridge into HTTP or any network-visible API.

## Law Compliance Notes

- Law 1 HolyC Purity: no violation found in audited source surfaces.
- Law 2 Air-Gap Sanctity: no networking action performed; no QEMU/VM command executed.
- Law 3/8 Book-of-Truth: warning-level drift because prompt/token provenance lacks ledger anchors.
- Law 5 North Star Discipline: warning-level drift because fixed token-ID success can be mistaken for interactive prompt readiness.

Finding count: 5

## Read-Only Verification Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '1,40p;220,268p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md | sed -n '1,60p;95,125p;195,230p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/NORTH_STAR.md | sed -n '1,80p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/tokenizer/bpe.HC | sed -n '1,190p;11880,12080p;12850,12925p;13730,13795p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/inference.HC | sed -n '1,75p;1488,1605p;1870,2085p'
rg -n "Inference\\(|TokenizerBPE|UTF8|UTF-8|BPE" /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Adam /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Compiler /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Apps 2>/dev/null || true
```
