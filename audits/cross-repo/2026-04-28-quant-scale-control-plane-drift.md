# Cross-Repo Audit: Quant Scale Control-Plane Drift

Timestamp: 2026-04-28T13:36:58+02:00

Scope: cross-repo invariant check across read-only TempleOS and holyc-inference worktrees.

Repos inspected:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference`
- Sanhedrin audit branch: `codex/sanhedrin-gpt55-audit`

Audit angle: whether TempleOS trusted-model/profile policy is precise enough to govern holyc-inference's integer-only Q4_0/Q8_0 fp16-scale conversion, rounding, and validation semantics.

## Summary

The repos agree on the broad rule: trusted inference must be local, air-gapped, HolyC-only, and integer-only at runtime. The drift is narrower but important: holyc-inference has concrete Q4_0/Q8_0 scale conversion and rounding behavior, while TempleOS only names high-level manifest and deterministic-gate fields. The control plane cannot yet tell whether a trusted model was promoted under the same scale-sanitization, quantization, rounding, and parity profile that the runtime actually uses.

Finding count: 5 warnings, 0 critical findings.

## Findings

### WARNING-001: TempleOS requires quant/tokenizer manifest fields that the current inference manifest does not carry

Relevant laws:
- Law 4: Integer Purity
- Law 5: North Star Discipline
- Law 8: Book of Truth Immediacy and Hardware Proximity

Evidence:
- TempleOS WS14 requires a trusted model manifest schema with `model_id`, `sha256`, quant type, tokenizer hash, and provenance: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:261`.
- holyc-inference's current trusted manifest line format is only `<sha256_hex_64> <size_bytes_decimal> <relative_model_path>`: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/trust_manifest.HC:4`.
- The `TrustManifestEntry` struct stores only `sha256_hex`, `size_bytes`, and `rel_path`: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/trust_manifest.HC:31`.
- holyc-inference's north star specifically depends on a Q4_0 GPT-2 124M weight blob on `shared.img`: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/NORTH_STAR.md:16`.

Impact:

The same byte hash can be trusted without Sanhedrin-visible evidence of the quant profile, tokenizer identity, model id, or provenance TempleOS says must exist. That leaves the control plane unable to distinguish a Q4_0 artifact promoted under integer-only assumptions from another local file that merely has a matching path/hash record.

Recommended closure:

Extend the shared manifest contract to include `model_id`, `format`, `quant_type`, `tokenizer_hash`, `scale_policy`, `rounding_policy`, and `provenance`. Book-of-Truth model-promotion events should log the same fields locally.

### WARNING-002: fp16 scale exceptional values saturate in runtime code but are not a promotion-policy field

Relevant laws:
- Law 4: Integer Purity
- Law 5: North Star Discipline

Evidence:
- holyc-inference quantization docs say runtime converts `d_fp16` to fixed-point integer once per block and then uses integer math only: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/docs/QUANTIZATION.md:21`.
- The documented scale conversion is `d_q16 = Round(d_fp16 * (1 << SCALE_SHIFT))`: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/docs/QUANTIZATION.md:66`.
- Q4_0 scale conversion maps fp16 exponent `0x1F` to saturated signed magnitudes, not an error: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/quant/q4_0.HC:211`.
- Q8_0 scale conversion does the same for fp16 INF/NAN encodings: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/quant/q8_0.HC:136`.
- TempleOS manifest/gate wording names quant type and deterministic parity, but not allowed fp16 scale classes, NaN/Inf handling, subnormal handling, or saturation policy: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:261`.

Impact:

This is still integer-only execution, so it is not a direct Law 4 violation. The drift is that a hostile or malformed model can carry non-finite fp16 scales and still reach a deterministic saturated integer value unless trusted promotion explicitly rejects or records that policy. Future parity baselines could bless saturated behavior without TempleOS knowing it accepted anomalous weight blocks.

Recommended closure:

Define `scale_policy` for trusted models: either reject fp16 NaN/Inf at quarantine or explicitly allow saturation with a Book-of-Truth count of saturated blocks. Treat any non-zero saturation count as promotion-blocking for `secure-local` unless there is a documented exception.

### WARNING-003: Q4_0/Q8_0 scale conversion logic is duplicated across runtime files without a single named ABI

Relevant laws:
- Law 4: Integer Purity
- Law 5: North Star Discipline

Evidence:
- `Q4_0F16ToQ16` appears in both `src/quant/q4_0.HC` and `src/quant/q4_0_dot.HC`: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/quant/q4_0.HC:184`; `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/quant/q4_0_dot.HC:53`.
- `Q8_0F16ToQ16` appears in both `src/quant/q8_0.HC` and `src/quant/q8_0_dot.HC`: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/quant/q8_0.HC:109`; `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/quant/q8_0_dot.HC:88`.
- Q4_0/Q8_0 block structs are also redefined across quant, dot, AVX2, and matmul files: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/quant/q4_0.HC:32`; `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/quant/q4_0_dot_avx2.HC:23`; `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/matmul/q4_0_matmul.HC:18`.

Impact:

The duplicate functions currently appear aligned, but the control plane has no single symbol or versioned ABI to hash, attest, or compare. A future hot-path edit could change dot-kernel scale handling while dequantization tests still pass, creating a hidden difference between "trusted quant type" and actual runtime arithmetic.

Recommended closure:

Name one canonical scale ABI, for example `QuantF16ToQ16PolicyV1`, and require all dequant, dot, AVX2, and matmul code paths to use or prove byte-for-byte parity with it. Include the ABI version in manifest, policy digest, and deterministic gate output.

### WARNING-004: Rounding semantics differ by call path and are not bound by TempleOS deterministic gate wording

Relevant laws:
- Law 4: Integer Purity
- Law 5: North Star Discipline

Evidence:
- holyc-inference docs say final rescale back to Q16 is a right shift, but also say deterministic shift/round policy is applied at layer boundaries only: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/docs/QUANTIZATION.md:86`; `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/docs/QUANTIZATION.md:114`.
- Q4_0 has a full-dot path that rounds once from total Q32 to Q16: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/quant/q4_0_dot.HC:166`.
- Q4_0 row kernels also document per-block Q32-to-Q16 rounding before summation: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/quant/q4_0_dot.HC:198`.
- Q8_0 has both total-dot rounding and per-block Q16 accumulation paths: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/quant/q8_0_dot.HC:212`; `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/quant/q8_0_dot.HC:232`.
- TempleOS deterministic gate wording requires fixed prompt/seed/logit-window parity, but does not name a rounding profile or call-path profile: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:263`.

Impact:

Both approaches can be deterministic and integer-only, but they are not equivalent. A `secure-local` gate can pass on one rounding path while production dispatch uses another, producing logit drift that is not visible as a manifest or policy mismatch.

Recommended closure:

Add a `rounding_profile` field to the policy digest and manifest. Deterministic inference gates should state whether each matrix path uses `round_total_q32_once`, `round_per_block_q16`, or another profile, and Book-of-Truth should log the profile with the trusted run.

### WARNING-005: Host validation tolerances do not match the north-star bit-exact claim for quant math evidence

Relevant laws:
- Law 4: Integer Purity
- Law 5: North Star Discipline

Evidence:
- holyc-inference north star requires the output to match reference bit-exactly: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/NORTH_STAR.md:18`.
- Q4_0 dequant tests intentionally allow a tolerance against a float path because integer scale rounding happens once per block: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_q4_0_dequant.py:163`.
- Q8_0 dequant tests similarly allow a tolerance of 128 against the float reference path: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_q8_0_dequant.py:169`.
- Q4_0 dot tests allow a Q32 tolerance of 35,000,000 against a float reference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_q4_0_dot.py:220`.
- Q8_0 dot tests allow a Q32 tolerance of 700,000,000 against a float reference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_q8_0_dot.py:365`.

Impact:

The tests also assert exact integer-path equality, so this is not a direct runtime bug. The control-plane problem is evidentiary: "matches llama.cpp/GGML bit-exactly" and "within deterministic tolerance against a float reference" are different claims. TempleOS' deterministic promotion gate needs to know which claim is being certified.

Recommended closure:

Split validation labels: `integer_path_exact` for HolyC internal parity, `float_reference_tolerance` for host sanity checks, and `llama_cpp_bit_exact` for promotion eligibility. Only the last two should be compared to external reference outputs, and only `llama_cpp_bit_exact` should satisfy TempleOS WS14-05.

## Law Compliance Notes

- No trinity source code was modified.
- No VM or QEMU command was executed.
- Air-gap posture was preserved; no networking work was performed.
- Findings are warning-level cross-repo contract drift, not current critical Law 1 or Law 2 violations.

## Evidence Commands

```bash
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '258,264p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/NORTH_STAR.md | sed -n '15,20p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/docs/QUANTIZATION.md | sed -n '1,134p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/trust_manifest.HC | sed -n '1,40p'
rg -n "^I64 Q[48]_0F16ToQ16|^class Q[48]_0Block|^I32 Q[48]_0DotProductBlocksQ32ToQ16|^I32 Q[48]_0DotProductBlocksQ16Accumulate" /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/quant /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/matmul
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_q4_0_dequant.py | sed -n '137,166p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_q8_0_dequant.py | sed -n '148,171p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_q4_0_dot.py | sed -n '196,226p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_q8_0_dot.py | sed -n '339,370p'
```
