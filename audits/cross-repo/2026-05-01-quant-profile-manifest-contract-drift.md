# Cross-Repo Audit: Quant Profile / Trust Manifest Contract Drift

Audit timestamp: 2026-05-01T14:32:33+02:00

Audit angle: cross-repo invariant check

Repos reviewed:
- TempleOS: `9f3abbf263982bf9344f8973a52f845f1f48d109`
- holyc-inference: `2799283c9554bea44c132137c590f02034c8f726`

Scope:
- TempleOS trust-plane model import, schema, and promotion fields in `Kernel/BookOfTruth.HC`
- holyc-inference quantization profile selection and model manifest surfaces in `src/runtime/quant_profile.HC`, `src/runtime/policy_digest.HC`, `src/model/trust_manifest.HC`, `docs/GGUF_FORMAT.md`, and `docs/QUANTIZATION.md`

No TempleOS or holyc-inference source files were modified. No QEMU, VM, networking, package-manager, or liveness command was executed.

## Invariant Expected

TempleOS owns the trust plane for model import, quarantine, verification, deterministic gate, build gate, and promotion. holyc-inference owns throughput-plane quantization modes and kernels. The handoff between those planes must make a promoted model's quantization contract unambiguous enough that TempleOS can tell whether the inference runtime is using a quant mode that matches the trusted manifest and GGUF tensor layout.

## Findings

### WARNING: TempleOS stores `quant` as an unconstrained byte while holyc-inference defines semantic quant-mode enums

Evidence:
- TempleOS `CBookTruthModelEntry` stores only `quant` as an `I64` field with no named enum next to model state/provenance.
- TempleOS schema validation accepts any value `0..255` and marks only values outside that range invalid.
- TempleOS import event payload stores only `(quant & 0xFF)`.
- holyc-inference defines `QUANT_MODE_Q4_0 = 1`, `QUANT_MODE_Q8_0 = 2`, and `QUANT_MODE_MIXED_Q4Q8 = 3`.
- holyc-inference GPU security/perf rows separately use `GPU_SEC_PERF_QUANT_Q4_0 = 40` and `GPU_SEC_PERF_QUANT_Q8_0 = 80`.

Why this matters:
- The same byte slot can carry at least two incompatible vocabularies today: runtime profile modes `1/2/3` and GPU perf matrix levels `40/80`.
- TempleOS can promote a model with `quant=40` or `quant=3` because both pass schema, but it has no local definition that says whether either means manifest quantization, selected runtime kernel mode, or performance-row label.
- This is a Law 5 / cross-repo contract warning, not a direct Law 1 or Law 2 violation.

Recommended remediation:
- Define one shared quant vocabulary for the trust-plane ABI, with explicit values for GGUF tensor type / runtime mode / profile selection when they differ.
- Make TempleOS reject unknown trust-plane quant values instead of accepting every byte.
- Add a parity smoke that asserts TempleOS `BOT_MODEL_QUANT_*` values match holyc-inference `QUANT_MODE_*` or documents the translation table.

### WARNING: Model trust manifests contain hash/size/path only, so TempleOS cannot bind trusted promotion to the quant mode selected by inference

Evidence:
- holyc-inference `TrustManifestEntry` contains `sha256_hex`, `size_bytes`, and `rel_path`.
- The manifest line format is documented as `<sha256_hex_64> <size_bytes_decimal> <relative_model_path>`.
- No manifest field carries declared GGUF tensor type set, quant profile, architecture, tokenizer hash, model id, or policy digest.
- TempleOS `BookTruthModelImport(...)` separately requires `quant` and `tok_hash`, but this value is not derivable from the current holyc-inference manifest format.

Why this matters:
- Hash and size prove file identity, but they do not prove the quantization contract TempleOS thinks it is authorizing.
- A trusted manifest entry for `models/tinyllama-q4_0.gguf` relies on filename convention for Q4_0 semantics; TempleOS cannot cross-check that against parsed tensor types or the inference quant profile.
- Law 5 North Star Discipline is implicated because secure-local promotion evidence can claim trusted-load readiness without a complete cross-plane model contract.

Recommended remediation:
- Extend the manifest contract or add a companion attestation tuple containing `model_id`, `gguf_arch`, `tokenizer_hash`, `quant_contract`, `tensor_type_mask`, and `policy_digest`.
- Require TempleOS promotion to compare `BookTruthModelImport.quant` against that tuple before `BookTruthModelPromote(...)` can succeed in secure-local.

### WARNING: Policy digest excludes quant profile selection, so secure-local parity can hold while quant behavior changes

Evidence:
- holyc-inference policy digest mixes profile id, secure-default flag, IOMMU, Book-of-Truth GPU hooks, quarantine gate, and hash-manifest gate.
- The digest does not mix `quant_mode`, `preferred_block_rows`, `prefetch_distance`, speculative decode state, or prefix cache state from `QuantProfileSelection`.
- `QuantProfileSelectForProfileChecked(...)` changes quant mode by profile/preference: secure-local accuracy selects Q8_0, secure-local throughput/balanced select Q4_0, and dev-local throughput/balanced select mixed Q4/Q8.

Why this matters:
- Sanhedrin or TempleOS can observe the same policy digest while the inference worker changes quant mode or block-row policy through preference selection.
- That weakens cross-repo proof for deterministic inference gates: the control plane can verify "secure-local guards are on" without verifying "the selected quant path matches the blessed baseline."

Recommended remediation:
- Include a stable quant-profile digest lane in `InferencePolicyDigestChecked(...)`.
- Or emit a separate `InferenceQuantProfileDigest;` and require TempleOS deterministic gate evidence to bind `(policy_digest, quant_profile_digest, model_hash, tokenizer_hash, prompt_hash, seed)`.

### WARNING: TempleOS parser gate records GGUF magic/header hash, but not tensor quant-type coverage

Evidence:
- TempleOS `BookTruthModelParseMask(...)` validates format, minimum/maximum bytes, fuzz score, magic, and nonzero header hash.
- holyc-inference `docs/GGUF_FORMAT.md` documents per-tensor `ggml_type` and explicitly names Q4_0 and Q8_0 block sizes/bytes.
- holyc-inference `GGUFModelInfoBuildCheckedNoPartial(...)` validates offsets and byte ranges, but its row schema includes only `rel_offset`, `byte_count`, `abs_start`, and `abs_end`.

Why this matters:
- A GGUF can pass TempleOS parse gate with the right magic and a header hash while containing tensor types that the runtime cannot safely handle or that do not match the imported `quant` byte.
- Offset/size validation is useful, but it is not enough for the trust plane to know whether the model's actual tensor quantization matches the approved inference path.

Recommended remediation:
- Add a parser attestation field for tensor-type mask/counts, at least `has_q4_0`, `has_q8_0`, `has_f32`, `unsupported_type_count`, and `mixed_quant`.
- Gate secure-local promotion on `(unsupported_type_count == 0)` and a match between tensor-type mask and the declared trust-plane quant contract.

### INFO: Core language and air-gap constraints remain intact in the audited surfaces

Evidence:
- Reviewed implementation surfaces are HolyC under `Kernel/`, `src/runtime/`, `src/model/`, `src/gguf/`, and docs/tests.
- The audit did not find added networking, sockets, HTTP, DNS, DHCP, TLS, package-manager, QEMU, or VM launch behavior in the reviewed quant/profile/manifest paths.
- The inference quantization docs and runtime code keep the math contract integer-only for runtime tensor operations.

## Validation Performed

- `git -C TempleOS rev-parse HEAD`
- `git -C holyc-inference rev-parse HEAD`
- `nl -ba TempleOS/Kernel/BookOfTruth.HC | sed -n '130,190p;13420,13580p;13640,13780p'`
- `nl -ba holyc-inference/src/runtime/quant_profile.HC | sed -n '1,260p'`
- `nl -ba holyc-inference/src/runtime/policy_digest.HC | sed -n '1,220p'`
- `nl -ba holyc-inference/src/model/trust_manifest.HC | sed -n '1,260p'`
- `nl -ba holyc-inference/src/gguf/model_info.HC | sed -n '1,220p'`
- `rg -n "BOT_MODEL.*(Q4|Q8|QUANT)|QUANT_MODE|Q4_0|Q8_0|quant<|quant>" TempleOS/Kernel TempleOS/MODERNIZATION`
- `rg -n "QUANT_MODE_|quant_mode|Q4_0|Q8_0|MIXED|ggml_type|GGML_TYPE_Q" holyc-inference/src holyc-inference/docs holyc-inference/tests/test_runtime_quant_profile.py`

## Verdict

Record 4 warning findings. The repos are directionally aligned on secure-local and integer-only inference, but the quantization contract is not yet a single shared ABI. TempleOS can verify model identity and basic gate status, while holyc-inference can select multiple quant modes whose semantics are not bound into the manifest, TempleOS promotion gate, or policy digest.
