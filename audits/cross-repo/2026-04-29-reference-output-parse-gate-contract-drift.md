# Cross-Repo Audit: Reference Output and Parse-Gate Contract Drift

Date: 2026-04-29T19:00:49+02:00

Scope: Retroactive cross-repo invariant check between `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `d9c3b620dbe9cf8bde884ed11c8ec1df99a68e89` and `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `485af0ea41a239c8393542d6e0e2fc5944f30f53`.

This audit was read-only against TempleOS and holyc-inference. It did not run QEMU or any VM command, did not inspect live loop liveness, and did not modify trinity source code.

## Question

Does holyc-inference's GPT-2 Q4_0 reference-output generator produce evidence that can satisfy TempleOS' new Book-of-Truth model parse/promotion gate?

Short answer: no. TempleOS now records a model parse result on the model row and may gate promotion on parse failure, while holyc-inference now has a host-side reference token fixture updater. The two evidence contracts are not linked by model hash, tokenizer hash, header hash, prompt identity, parse event sequence, or Book-of-Truth append proof.

## Findings

1. WARNING: TempleOS parse success is a manually supplied summary, not a parser-bound artifact identity.
   - Evidence: `BookTruthModelParseMask(fmt, magic, hdr_hash, bytes, fuzz)` checks only format ID, magic, byte range, fuzz byte, and nonzero `hdr_hash`; `BookTruthModelParseRun(...)` stores those supplied fields on the model row and emits a note/failure event.
   - Evidence: the reviewed function does not receive a model path, model SHA, tokenizer hash, tensor metadata digest, reference prompt ID set, or reference output token.
   - Impact: a future caller can mark a model as parsed using a detached header summary that is not proven to be the same artifact holyc-inference used to generate the GPT-2 Q4_0 reference output.
   - Required closure: require parse evidence to bind `model_id`, model SHA, tokenizer hash, GGUF header hash, tensor metadata digest, prompt IDs, seed, and expected next token in one shared evidence tuple.

2. WARNING: parse-gate enforcement is optional when no parse attempt has been recorded.
   - Evidence: promotion marks `BOT_MODEL_GATE_PARSE` only when `parse_fmt != 0 && !parse_ok`, and `ok` remains true when `parse_fmt == 0` as long as schema and verify checks pass.
   - Impact: TempleOS can promote a trusted model with no parser-hardening record at all. That undercuts the intended bridge to holyc-inference's reference-output evidence because reference parity can be treated as separate from model parse readiness.
   - Required closure: in secure-local promotion, require a positive parse record for the same model before trust, not merely "no failed parse exists."

3. WARNING: holyc-inference reference output fixture does not carry TempleOS trust fields.
   - Evidence: `tests/reference_q4_gpt2.py --emit-json` returns only `model_id`, `seed`, `prompt_token_ids`, `next_token_id`, and fixture path; update mode writes `updated_at_utc`, `source`, `model_id`, `seed`, `prompt_token_ids`, and `next_token_id`.
   - Evidence: the default fixture `tests/fixtures/reference_q4_gpt2.json` is currently absent in the reviewed checkout, so default mode cannot produce a reference token without prior host-side fixture creation.
   - Impact: even when present, the fixture cannot prove that the token was produced from the same artifact imported, parsed, verified, and promoted by TempleOS.
   - Required closure: extend the fixture schema with model SHA256, tokenizer digest, GGUF magic/version/header hash, tensor metadata digest, parse gate result, TempleOS model ID, and Book-of-Truth event sequence/hash identity.

4. WARNING: the reference updater can capture arbitrary shell output without a local/offline provenance guard.
   - Evidence: `_capture_token` runs `subprocess.run(capture_cmd, shell=True, ...)`; the test suite proves this by passing a shell `printf` command and only checking that `source == "capture-cmd"`.
   - Impact: the reference token can be refreshed from any command string, including a non-local or network-dependent tool, while the fixture records only the command text and an excerpt. This does not violate HolyC purity because it is host-side tooling, but it weakens the air-gapped secure-local evidence chain.
   - Required closure: mark reference fixture generation as offline-only, reject obvious network commands, record executable path/hash, argv list, working directory, input model path/hash, and command return metadata.

5. INFO: no direct LAWS.md source violation was found in this pass.
   - TempleOS changes remain HolyC in core paths, holyc-inference reference tooling is under `tests/`, and this audit did not observe networking additions in core source. The issue is cross-repo contract drift: TempleOS' model parse gate and holyc-inference's reference token generator produce separate attestations that cannot currently be joined into one trusted north-star proof.

## Suggested Gate

Add a Sanhedrin cross-repo check that fails north-star evidence claims unless all of these are true:

- holyc-inference reference fixture includes model SHA256, tokenizer digest, GGUF header hash, prompt token IDs, seed, and expected next token.
- TempleOS `BookTruthModelParseRun` evidence for the same `model_id` includes the same model SHA/tokenizer/header identities or references an immutable manifest row containing them.
- secure-local `BookTruthModelPromote` requires a positive parse record, not merely absence of a failed parse record.
- reference fixture generation is local/offline-only and records executable provenance for the captured reference command.
- at least one replayable fixture shows the same identity tuple in holyc-inference reference JSON and TempleOS `BookTruthModelStatus`/`BookTruthModelParseStatus` output.

## Evidence Commands

```
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC | sed -n '12472,12725p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/bookoftruth-model-parse-smoke.sh | sed -n '1,120p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/reference_q4_gpt2.py | sed -n '1,190p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_reference_q4_gpt2.py | sed -n '1,120p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/NORTH_STAR.md | sed -n '1,60p'
test -f /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/fixtures/reference_q4_gpt2.json || echo missing
```
