# Cross-Repo Audit: Tokenizer Artifact Trust Contract Drift

Date: 2026-04-29T08:52:15+02:00

Scope: Retroactive cross-repo invariant check between `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `af6e9eab115bee5528e364535ba75617d15033fc` and `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `485af0ea41a239c8393542d6e0e2fc5944f30f53`.

This audit was read-only against TempleOS and holyc-inference. It did not run QEMU or any VM command and did not inspect live liveness.

## Question

Does TempleOS' trusted-model schema commit to the same tokenizer artifact identity that holyc-inference uses for BPE encode/decode?

Short answer: no. TempleOS requires a `tok_hash` as part of model quarantine, verification, and manifest status, but holyc-inference's trusted manifest currently verifies only model-file SHA256, size, and relative path. The BPE runtime accepts caller-provided rank/vocab tables and special-token metadata, but no reviewed source binds those tables to a TempleOS-owned tokenizer hash or to the trusted manifest row.

## Findings

1. WARNING: TempleOS has a tokenizer-hash requirement that holyc-inference's manifest cannot satisfy.
   - Evidence: TempleOS marks WS14-03 complete for a trusted model manifest schema containing `model_id`, `sha256`, quant type, tokenizer hash, and provenance. `CBookTruthModelEntry` stores `tok_hash`, and `BookTruthModelSchemaMask` marks `tok_hash==0` as schema bit `8`.
   - Evidence: holyc-inference's manifest line format is only `<sha256_hex_64> <size_bytes_decimal> <relative_model_path>`, and `TrustManifestEntry` stores only `sha256_hex`, `size_bytes`, and `rel_path`.
   - Impact: a model can pass holyc-inference trusted-load verification without producing the tokenizer identity TempleOS requires for secure-local promotion.
   - Required closure: extend the shared manifest ABI with tokenizer hash fields, and require the inference verifier to reject trusted load unless the tokenizer artifact identity matches the TempleOS model row.

2. WARNING: BPE rank and vocabulary tables are runtime inputs, not manifest-bound trusted artifacts.
   - Evidence: `TokenizerBPEMergeApplyBestPriorityChecked` accepts `rank_left_tokens`, `rank_right_tokens`, `rank_values`, and `rank_merged_tokens` buffers from the caller, and decode helpers accept `vocab_piece_bytes`, `vocab_piece_offsets`, and `vocab_piece_lens`.
   - Evidence: the reviewed BPE source has GGUF metadata lookups only for special token IDs (`tokenizer.ggml.bos_token_id`, `tokenizer.ggml.eos_token_id`, and `tokenizer.ggml.padding_token_id`). The source search found no HolyC loader binding `tokenizer.ggml.tokens`, `tokenizer.ggml.merges`, or equivalent BPE table bytes to a hash checked by `TrustManifestEntry`.
   - Impact: the model weights can be trusted while the tokenizer tables that define prompt/token semantics remain swappable at the worker-plane boundary.
   - Required closure: define a tokenizer artifact digest over the exact vocab bytes, piece offsets/lens, merge rows, merged-token rows, and special-token tuple consumed by the HolyC tokenizer.

3. WARNING: TempleOS model verification compares `tok_hash`, but it cannot prove that holyc-inference used the same BPE tables during tokenization.
   - Evidence: `BookTruthModelVerify` checks stored `sha_hi`, `sha_lo`, and `tok_hash` against caller values, and `BookTruthModelManifestStatus` prints `tok_hash`; however, no cross-repo evidence path maps that `tok_hash` to the holyc-inference BPE table buffers used by encode/decode.
   - Impact: a secure-local audit row can truthfully show a nonzero tokenizer hash while the inference runtime still uses unrelated caller-provided BPE arrays.
   - Required closure: make tokenizer-table digest computation part of the inference trusted-load path and ledger the digest before first tokenization.

4. WARNING: special-token policy is not included in the trust boundary.
   - Evidence: `TokenizerBPESpecialTokensResolveCheckedNoPartial` resolves BOS/EOS/PAD from GGUF metadata or fallback values and allows missing tokens when configured. The trust manifest does not encode required BOS/EOS/PAD IDs or fallback policy.
   - Impact: two runs can share the same model SHA and tokenizer table hash but differ in BOS/EOS/PAD policy, changing generated token streams and weakening deterministic-gate evidence.
   - Required closure: include special-token IDs and missing-token fallback policy in the tokenizer digest or model-promotion payload.

5. INFO: no direct LAWS.md source violation was found in this pass.
   - The reviewed implementation remains HolyC in core paths and does not add networking. The issue is cross-repo contract drift: TempleOS' control plane is stricter than the current inference trust manifest and tokenizer loader boundary.

## Suggested Gate

Add a Sanhedrin cross-repo check that fails secure-local completion claims unless all of these are true:

- TempleOS `BookTruthModelImport`/`Verify` receives a nonzero tokenizer digest.
- holyc-inference trusted manifest contains the same tokenizer digest and rejects mismatches.
- the digest covers BPE vocab bytes, offsets, lengths, merge ranks, merged-token IDs, and special-token policy.
- at least one fixture proves the same digest value appears in both the TempleOS model row and the holyc-inference trusted-load evidence.

## Evidence Commands

```
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '252,266p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC | sed -n '120,155p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC | sed -n '12390,12625p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/trust_manifest.HC | sed -n '1,220p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/tokenizer/bpe.HC | sed -n '1,155p;1880,1975p;13730,13855p'
rg -n "TokenizerBPE.*GGUF|GGUF.*Tokenizer|vocab.*GGUF|tokenizer\\.ggml\\.tokens|tokenizer\\.ggml\\.merges|tokenizer\\.ggml\\.model|tokenizer\\.ggml" /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests -g '*.HC' -g '*.py'
```
