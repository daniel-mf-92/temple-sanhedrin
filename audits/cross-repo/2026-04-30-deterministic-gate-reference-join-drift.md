# Cross-Repo Audit: Deterministic Gate Reference Join Drift

Audit timestamp: 2026-04-30T01:33:17+02:00

Audit owner: gpt-5.5 sibling, retroactive / historical scope only

Repos examined:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `e4543e10d3dc1c56ea6f5ce491ea1dfee54a1490`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `485af0ea41a239c8393542d6e0e2fc5944f30f53`
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit` at `0870548ee7be1c5750013b327daaaccadc792e3a`

Audit angle: cross-repo invariant check. No TempleOS or holyc-inference source code was modified. No QEMU, VM, liveness watcher, process restart, deploy, package manager, remote service, or WS8 networking task was executed.

## Expected Invariant

The TempleOS deterministic model gate and holyc-inference reference-output path should share one reproducible join tuple:

`{model_id, model_sha256, tokenizer_hash, prompt_token_ids, prompt_hash_algorithm, seed_full_width, sampler_policy, logit_window_definition, logit_window_hash_algorithm, baseline_hash, expected_next_token_id, reference_fixture_hash, Book-of-Truth append proof}`

Without this tuple, a TempleOS `BookTruthModelDetRun(...)` pass and a holyc-inference `reference_q4_gpt2.py` pass can both be true while proving different facts.

Finding count: 5 findings: 5 warnings.

## Findings

### WARNING-001: TempleOS deterministic gate accepts opaque hashes that holyc-inference does not define

Applicable laws:
- Law 5: North Star Discipline
- Cross-repo secure-local promotion invariant

Evidence:
- TempleOS WS14-05 is complete for fixed prompt/seed/logit-window parity vs blessed baseline: `TempleOS/MODERNIZATION/MASTER_TASKS.md:258-264`.
- `BookTruthModelDetRun` accepts `prompt_hash`, `window_hash`, and `baseline_hash`, and declares success only when `prompt_hash != 0`, `baseline_hash != 0`, and `window_hash == baseline_hash`: `TempleOS/Kernel/BookOfTruth.HC:12800-12820`.
- holyc-inference reference output stores prompt token IDs and next token, but no `prompt_hash`, hash algorithm, logit-window hash, or baseline hash: `holyc-inference/tests/reference_q4_gpt2.py:123-129`.

Assessment:

The TempleOS control plane has no way to recompute or validate its opaque hashes from the current holyc-inference reference artifact. A caller can pass any equal non-zero `window_hash` and `baseline_hash` pair and satisfy the deterministic gate without proving the pair came from the blessed reference corpus.

Recommended closure:

Define one shared digest algorithm and canonical byte layout for `prompt_hash`, `window_hash`, and `baseline_hash`. The holyc-inference fixture should emit those exact fields, and TempleOS/Sanhedrin should reject deterministic gate evidence missing the matching fixture hash and algorithm version.

### WARNING-002: The reference artifact proves a next token, but TempleOS gates only a logit-window digest

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- holyc-inference North Star requires one GPT-2 forward pass that outputs the next-token id over serial and matches `tests/reference_q4_gpt2.py` bit-exactly: `holyc-inference/NORTH_STAR.md:15-19`.
- The reference generator's JSON output includes `model_id`, `seed`, `prompt_token_ids`, and `next_token_id`: `holyc-inference/tests/reference_q4_gpt2.py:150-157`.
- TempleOS `BookTruthModelDetRun` records `window_hash` and `baseline_hash`, but has no `expected_next_token_id`, `actual_next_token_id`, or `match` field in the deterministic gate state or event payload: `TempleOS/Kernel/BookOfTruth.HC:12820-12841`.

Assessment:

The two repos are certifying adjacent but non-identical properties. holyc-inference's north star is token equality, while TempleOS's gate is digest equality over an undefined window. If the future bridge hashes logits but the north-star runner compares token IDs, Sanhedrin cannot prove a TempleOS deterministic pass corresponds to the actual serial token correctness requirement.

Recommended closure:

Extend the shared deterministic proof with both levels: `logit_window_digest` and `{expected_next_token_id, actual_next_token_id, match}`. Secure-local promotion should require the token match and the logit-window digest when WS16/WS14 claims "prompt/seed/logit-window parity."

### WARNING-003: Full seed identity is split between status text and lossy ledger payload

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 5: North Star Discipline

Evidence:
- `BookTruthModelDetRun` stores the full `seed` in `det_seed` and status output: `TempleOS/Kernel/BookOfTruth.HC:12820-12824` and `13057-13068`.
- The Book-of-Truth event payload records only `((seed&0x7F)<<8)`: `TempleOS/Kernel/BookOfTruth.HC:12827-12831`.
- holyc-inference reference fixture stores the seed as an integer and defaults to `1234`: `holyc-inference/tests/reference_q4_gpt2.py:20-23` and `123-129`.

Assessment:

The status text can show the full seed while the canonical ledger payload cannot distinguish seeds that differ above bit 7. Since `1234 & 0x7F == 82`, the default reference seed already depends on data that is absent from the compact event payload. This weakens replay and makes historical ledger-only audits ambiguous.

Recommended closure:

Make full seed identity hash-chain-bound. Options include encoding a full-width seed digest in the payload series, adding a deterministic side entry immediately adjacent to the gate event, or making the event payload point to a sealed model-run proof row.

### WARNING-004: holyc-inference default reference fixture is absent, so TempleOS cannot bind to a committed blessed baseline

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- holyc-inference marks WS12-05 complete for the reference output generator: `holyc-inference/MASTER_TASKS.md:181-188`.
- The default fixture path is `tests/fixtures/reference_q4_gpt2.json`: `holyc-inference/tests/reference_q4_gpt2.py:20-23`.
- The current holyc-inference tree has no file under `tests/fixtures/`; a read-only `find tests/fixtures -maxdepth 2 -type f` returned no files.

Assessment:

TempleOS now has a deterministic gate that expects a blessed baseline, but the inference repo currently commits the generator rather than the baseline artifact. This leaves no immutable repository object for Sanhedrin to hash, compare, or cite when evaluating `baseline_hash`.

Recommended closure:

Commit a development-only reference fixture with explicit non-promotion provenance, or keep WS12-05 incomplete until a blessed fixture exists. For promotion evidence, require `reference_fixture_sha256` and include it in TempleOS deterministic gate status.

### WARNING-005: TempleOS smoke test checks symbols and print strings, not cross-repo proof compatibility

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- `automation/bookoftruth-model-det-smoke.sh` checks for marker constants, externs, selected function signatures, and status strings: `TempleOS/automation/bookoftruth-model-det-smoke.sh:30-40`.
- The smoke test does not parse a holyc-inference reference fixture, does not compute any prompt/window/baseline digest, and does not verify seed round-trip or token equality.
- holyc-inference's reference tests exercise manual token update, shell capture, and missing fixture behavior, but do not export a TempleOS-compatible deterministic proof tuple: `holyc-inference/tests/test_reference_q4_gpt2.py:20-75`.

Assessment:

Both sides have useful local checks, but no cross-repo fixture proves that the TempleOS gate and holyc-inference reference artifact can interoperate. This is the key drift: the gate can pass its smoke test while still being impossible to join to the reference corpus.

Recommended closure:

Add a Sanhedrin-owned read-only contract test with one canonical JSON fixture. It should compute the expected hashes, assert the TempleOS field names and widths, assert holyc-inference emits the same tuple, and fail if either repo changes the ABI without updating the shared contract.

## Non-Findings

- No Law 1 HolyC purity violation was found in the reviewed paths. TempleOS core changes are HolyC; holyc-inference Python code is under `tests/`, which LAWS.md permits for validation scripts.
- No Law 2 air-gap violation was found. This audit did not run QEMU or any networking command, and the reviewed files did not add guest networking.
- No Law 4 integer-purity violation was found in the reviewed inference runtime paths; this pass focused on evidence schema drift, not tensor arithmetic.

## Evidence Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '30,45p;255,280p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC | sed -n '12780,13160p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/bookoftruth-model-det-smoke.sh | sed -n '1,80p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/NORTH_STAR.md | sed -n '1,120p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md | sed -n '181,215p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/reference_q4_gpt2.py | sed -n '1,170p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_reference_q4_gpt2.py | sed -n '1,90p'
find /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/fixtures -maxdepth 2 -type f -print
```
