# Cross-Repo Audit: Fixed Prompt Token Contract Drift

Timestamp: 2026-05-02T06:24:40+02:00

Scope: read-only cross-repo invariant check across `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` and `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference`.

Audited heads:
- TempleOS: `9f3abbf263982bf9344f8973a52f845f1f48d109`
- holyc-inference: `2799283c9554bea44c132137c590f02034c8f726`
- Sanhedrin audit branch before this report: `eda02becf27b2cc59501358753babec755f5d50d`

No TempleOS or holyc-inference source files were modified. No QEMU, VM, live liveness watch, process restart, WS8 networking task, socket, NIC, TCP/IP, UDP, DNS, DHCP, HTTP, TLS, package-manager, or remote-runtime action was executed.

## Invariant Under Audit

The holyc-inference north star is not just "some prompt" and not just "some benchmark output". It requires one pure-HolyC forward pass inside the TempleOS guest on the fixed GPT-2 token sequence `[15496, 11, 995]` (`Hello, world`) and a next-token id over local serial. TempleOS owns the trust/control plane for deterministic model gates. The cross-repo invariant is:

1. benchmark input identity must be token-sequence identity, not only raw UTF-8 text identity;
2. the serial result must include the actual `next_token_id` and reference/comparison tuple;
3. TempleOS deterministic gate evidence must bind to the same prompt-token identity and result tuple that holyc-inference accepts.

## Findings

### WARNING 1. The north star names fixed token IDs, but the benchmark runner accepts arbitrary text prompts

Evidence:

- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/NORTH_STAR.md:17` defines the required prompt as token IDs `[15496, 11, 995]`.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py:79` through `89` load prompt rows as strings.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py:246` through `247` export raw prompt text and prompt id in host environment variables.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py:251` through `258` also writes the raw prompt text to the QEMU process stdin.

Impact: the benchmark input contract is text-based, while the deliverable is token-id based. Without a mandatory `[15496, 11, 995]` token tuple in the prompt file, command line, guest preamble, or result envelope, a run can hash and record `"Hello, world"` text without proving that the guest used GPT-2's intended tokenization.

Recommended closure: add a required `prompt_token_ids` field for north-star/secure-local profiles, fail closed unless it equals `[15496, 11, 995]` for the canonical smoke target, and include that tuple in the serial result and report JSON.

### WARNING 2. The accepted serial grammar has throughput metrics, but no next-token correctness field

Evidence:

- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/README.md:47` through `57` documents `BENCH_RESULT` examples with `tokens`, `elapsed_us`, and throughput.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py:207` through `212` extracts token counts from `tokens`, `generated_tokens`, `decode_tokens`, or `total_tokens`.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py:226` through `235` extracts or derives throughput.
- No inspected benchmark parser branch extracts `next_token_id`, `reference_token_id`, `logit_rank`, or `match`.

Impact: the grammar can validate "64 tokens generated at 4 tok/s" while not validating the one result the north star requires: the next-token id for the fixed prompt. This weakens Law 5 / North Star Discipline because throughput telemetry can masquerade as correctness progress.

Recommended closure: define a correctness envelope such as `BENCH_RESULT: {"prompt_token_ids":[15496,11,995],"next_token_id":...,"reference_token_id":...,"match":true,...}` and make it required for north-star profiles. Throughput fields should remain secondary telemetry.

### WARNING 3. TempleOS deterministic gate stores opaque U64 prompt/window hashes, not a token/result contract

Evidence:

- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC:176` through `205` define model gate state fields including `det_prompt_hash`, `det_window_hash`, and `det_baseline_hash`, but no prompt token count, token ids, next-token id, or tokenizer hash binding for the deterministic run itself.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC:13624` through `13626` expose `BookTruthModelDetRun(model_id, prompt_hash, seed, window_hash, baseline_hash, ...)`.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC:13641` through `13643` mark the deterministic gate ok when `prompt_hash != 0`, `baseline_hash != 0`, and `window_hash == baseline_hash`.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC:13664` through `13665` prints only prompt/window/baseline hashes.

Impact: TempleOS can certify deterministic parity on two equal opaque hashes without proving that the hashes correspond to the fixed GPT-2 token sequence or to the emitted next-token id. The trust plane and inference plane can therefore both say "deterministic pass" while speaking different prompt/result languages.

Recommended closure: extend the deterministic gate contract with prompt-token identity fields: token count, a stable digest over little-endian token IDs, tokenizer hash, next-token id, reference-token id, and match bit. Keep full token arrays out of the hot log if necessary, but bind the digest to a documented byte layout.

### WARNING 4. The host benchmark uses SHA-256 text identity while TempleOS uses U64 prompt hash identity

Evidence:

- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py:60` through `61` compute SHA-256 over UTF-8 prompt text.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py:284` through `285` store prompt id plus `prompt_sha256`.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/KExts.HC:119` through `121` publish the TempleOS deterministic gate as U64 `prompt_hash`, `window_hash`, and `baseline_hash`.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC:13963` through `13969` report those U64 values in deterministic status.

Impact: there is no documented truncation, endian, or domain-separation rule connecting the host's 256-bit text hash to TempleOS's 64-bit prompt hash. Even if both sides later add "prompt hash" checks, they may not compare the same bytes or the same semantic object.

Recommended closure: define one canonical prompt identity ABI. For north-star runs, prefer `prompt_tokens_le_sha256` over text hash; if TempleOS must keep a U64 field, define it as a named truncation of the SHA-256 digest and record the full digest in host artifacts.

### INFO 5. Existing tokenizer and reference-doc work gives enough substrate to close the drift without violating HolyC purity

Evidence:

- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md:98` through `100` keep BPE vocabulary load, encode, and decode as explicit workstream tasks.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/tokenizer/bpe.HC:31` through `154` already implement HolyC tokenizer special-token metadata helpers.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/docs/LLAMA_ARCH.md:149` through `154` require host-side validation against reference outputs for the same model/prompt/seed.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/docs/QUANTIZATION.md:125` through `133` already frame Python/C validation as host-side parity checks, not runtime dependencies.

Impact: this is contract drift, not a request for foreign runtime code or network dependencies. The likely remediation can stay within the allowed language policy: HolyC runtime emits token/result fields; host-side Python validates reports; no TempleOS guest networking is needed.

## Recommended Cross-Repo Contract

- Input identity: `prompt_token_ids=[15496,11,995]`, `prompt_token_count=3`, `tokenizer_sha256`, and `prompt_tokens_le_sha256`.
- Output identity: `next_token_id`, `reference_token_id`, `match`, `seed`, and optional `topk_window_hash`.
- TempleOS gate: `BookTruthModelDetRun` should bind to the same token digest and result tuple, not only opaque U64 prompt/window hashes.
- Benchmark acceptance: `status=pass` for north-star profiles requires the fixed prompt-token tuple and `match=true`.
- Air-gap: all of this remains local serial/file evidence only; no network transport or WS8 networking task is needed.

Finding count: 5

## Read-Only Commands Used

```bash
git rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/NORTH_STAR.md | sed -n '1,220p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py | sed -n '1,430p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/README.md | sed -n '1,220p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC | sed -n '160,220p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC | sed -n '13620,13690p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC | sed -n '13925,13975p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/KExts.HC | sed -n '110,134p'
rg -n "15496|Hello, world|next[-_ ]token|next_token|reference_token|token_id|token id|BENCH_RESULT|prompt_sha256|HOLYC_BENCH_PROMPT|tokenizer|vocab|bpe|encoder|decode|encode" NORTH_STAR.md MASTER_TASKS.md LOOP_PROMPT.md bench src tests docs -S
rg -n "Inference\\(|BENCH_RESULT|HOLYC_BENCH|prompt|token|token_id|serial|BoT:|BookTruth|shared\\.img|qemu" MODERNIZATION Kernel Adam Apps automation -S
```
