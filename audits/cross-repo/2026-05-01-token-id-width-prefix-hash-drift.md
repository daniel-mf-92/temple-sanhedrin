# Cross-Repo Audit: Token-ID Width / Prefix Hash Drift

Audit angle: cross-repo invariant check. TempleOS and holyc-inference source trees were read-only. No QEMU, VM, networking, WS8, or trinity source modification was executed.

## Question

Does the TempleOS trust plane define token identity with the same width and byte encoding that holyc-inference uses when it hashes prompt prefixes for cache reuse and audit evidence?

Short answer: no. holyc-inference's tokenizer and generation paths use signed integer token IDs (`I32`/`I64`) and the north-star GPT-2 prompt already includes IDs greater than 255, but `InferencePromptPrefixHashQ64Checked` accepts `U8 *tokens` and hashes one byte per token. TempleOS records model/tokenizer/prompt proof as hashes and deterministic gate fields, but does not define the canonical token-ID serialization width that would prevent byte-truncated prompt-prefix aliases.

## Findings

1. WARNING - Prefix-cache hashing truncates token identity to one byte per token.
   Evidence: `holyc-inference/src/runtime/prefix_cache.HC:47-75` declares `InferencePromptPrefixHashQ64Checked(U8 *tokens, I64 token_count, ...)` and mixes `tokens[idx]` directly into the FNV lane. There is no width tag, endian rule, or rejection of IDs outside 0..255 at that boundary.
   Impact: prefix hashes for token IDs that differ only above the low byte are indistinguishable before the length mix. A cache hit can therefore stand for the wrong prompt if higher-width token IDs are coerced into this helper.
   Required closure: make the prefix hash consume canonical fixed-width token IDs, e.g. little-endian `U32`/`I32` lanes plus a version/domain tag, or reject use with token IDs outside `U8` range before secure-local cache admission.

2. WARNING - The tokenizer surface uses `I32` token IDs, so the prefix hash input type is narrower than the producer contract.
   Evidence: `holyc-inference/src/tokenizer/bpe.HC:31-55` resolves special token IDs into `I32`; `src/tokenizer/bpe.HC:921-973`, `1458-1494`, and `1519-1625` operate on `I32 *token_ids` and `I32` merged-token values.
   Impact: a future integration can pass tokenizer output through a byte buffer to the prefix cache and silently lose high bits. The reviewed code does not show a shared adapter that serializes `I32` tokens into the prefix-hash input without truncation.
   Required closure: add an explicit tokenizer-to-prefix-hash adapter whose signature makes the width obvious, and test it with IDs above 255.

3. WARNING - The inference north star already requires token IDs above one byte.
   Evidence: `holyc-inference/NORTH_STAR.md:16-18` fixes the prompt token sequence as `[15496, 11, 995]`. If reduced to low bytes, that sequence becomes `[136, 11, 227]`; many distinct GPT-2 token IDs can share those low bytes.
   Impact: the very first target prompt cannot be faithfully represented by `U8 *tokens` as token IDs. Any secure-local prefix reuse or prompt-prefix proof based on that helper would be proving a byte projection, not the canonical prompt.
   Required closure: add a north-star fixture that asserts the prefix/prompt digest of `[15496, 11, 995]` is computed from full-width token IDs and fails if `[136, 11, 227]` matches it.

4. WARNING - TempleOS trust-plane fields name `prompt_hash` and `tok_hash` but not the token serialization ABI.
   Evidence: `TempleOS/MODERNIZATION/MASTER_TASKS.md:258-277` marks trusted model manifest schema, deterministic inference gate, and policy-digest handshake work around model/tokenizer/prompt proof; `TempleOS/Kernel/BookOfTruth.HC:839-853` exposes `tok_hash` and `BookTruthModelDetRun(model_id, prompt_hash, seed, window_hash, baseline_hash, ...)`.
   Impact: TempleOS can require hashes but still accept an inference-side proof whose prompt hash was computed over byte-truncated token IDs. That is cross-repo drift from the control-plane goal that TempleOS remains the source of truth for secure-local inference evidence.
   Required closure: define `prompt_hash_v0` as a canonical byte encoding: token count, token ID width, endian order, tokenizer hash, BOS/EOS policy, and model family.

5. WARNING - Existing prefix-cache audit tuples do not carry enough metadata to detect token-width aliasing after the fact.
   Evidence: `holyc-inference/src/runtime/prefix_cache.HC:30-38` stores `prefix_hash`, `prefix_tokens`, `kv_start_token`, `kv_token_count`, and `last_used_tick`; lookup chooses by `prefix_hash` and prefix length at `src/runtime/prefix_cache.HC:1906-1960`. The tuple does not store `token_width`, `tokenizer_hash`, `model_id`, or a full prompt digest.
   Impact: Sanhedrin can see that a cache decision happened, but cannot retroactively distinguish a true full-width token-prefix hit from a low-byte alias hit.
   Required closure: extend secure-local cache evidence with `{model_id, tokenizer_hash, token_width_bits, prompt_hash_v0, prefix_hash, prefix_tokens, decision, ledger_seq/hash}` and treat worker-only cache hashes as advisory.

## Collision Example

The audited north-star prompt demonstrates the problem without executing any VM:

```text
full token IDs: [15496, 11, 995]
low bytes:      [136, 11, 227]
```

Any prefix proof over `U8 *tokens` can only see the low-byte row. Likewise, `[15496, 15752, 16008]` collapses to `[136, 136, 136]` under low-byte projection.

## Law Mapping

- Law 3 / Law 8: Book-of-Truth evidence must be immutable and close to the act being recorded; a prompt-prefix proof that omits high token bits is not sufficient evidence of the actual prompt act.
- Law 5: cache and prompt-proof work can look like meaningful north-star progress while leaving the GPT-2 token identity under-specified.
- TempleOS secure-local doctrine: TempleOS owns trust decisions, but the current cross-repo contract leaves token serialization to worker-local convention.

## Recommended Gate

Add a small cross-repo fixture with:

```text
tokenizer_hash=<known>
token_width_bits=32
prompt_token_ids=[15496,11,995]
prompt_hash_v0=<canonical full-width digest>
low_byte_prompt_hash_must_not_equal=true
```

The fixture should be consumed by holyc-inference tests and by TempleOS/Sanhedrin policy checks before secure-local prefix-cache reuse or deterministic prompt proof is credited.

## Commands Run

```bash
rg -n "token|vocab|BPE|merge|GGUF|prompt|context|ctx|seq|position|rope|Book|Truth|serial|profile|policy" /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Adam /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Apps
rg -n "token|vocab|BPE|merge|GGUF|prompt|context|ctx|seq|position|rope|Book|Truth|serial|profile|policy" /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/docs /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation
rg -n "prefix.*cache|cache.*prefix|token.*width|width.*token|U8 \\*tokens|token id|token_id|vocab_size|prompt prefix" audits/cross-repo audits/trends audits/backfill audits/research
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/prefix_cache.HC | sed -n '1,120p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/tokenizer/bpe.HC | sed -n '1,170p;900,980p;1450,1520p;1518,1628p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/NORTH_STAR.md | sed -n '1,80p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '20,58p;252,280p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC | sed -n '830,860p'
python3 - <<'PY'
prompt=[15496,11,995]
print([x & 0xff for x in prompt])
print([15496,15496+256,15496+512])
print([x & 0xff for x in [15496,15496+256,15496+512]])
PY
```
