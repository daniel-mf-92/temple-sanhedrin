# Cross-Repo Fixture Provenance Contract Drift Audit

Timestamp: 2026-04-29T22:53:13+02:00
Scope: current committed heads of `TempleOS` and `holyc-inference`.
Audit angle: cross-repo invariant checks.
TempleOS head: `00d1bdc feat(modernization): codex iteration 20260429-205149`.
holyc-inference head: `485af0ea feat(inference): codex iteration 20260429-064100`.

No trinity source files were modified. No QEMU, VM, WS8, networking, or live liveness command was executed. This audit read committed files only; the one runtime check was `python3 tests/reference_q4_gpt2.py`, which only attempted to read its default local fixture and failed because that fixture is absent.

## Invariant Under Audit

Host-side fixtures are useful only when Sanhedrin and downstream gates can distinguish synthetic replay material from real guest/model truth. TempleOS Book-of-Truth smoke tests and holyc-inference GPT-2 reference checks currently expose different, weak provenance contracts:

- TempleOS can synthesize Book-of-Truth-looking serial evidence by default.
- holyc-inference's North Star depends on a reference fixture that is not committed, while the updater can capture arbitrary shell output without an offline/provenance guard.
- Neither side exports a shared minimum evidence schema such as `source_class`, `synthetic_fixture`, `generated_by`, `input_artifact_sha256`, `capture_cmd_sha256`, `network_forbidden`, and `guest_airgap_proof`.

## Findings

1. **WARNING - TempleOS mem-map smoke defaults to synthetic serial evidence.**
   Evidence: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/bookoftruth-memmap-smoke.sh:21` documents fixture mode as the default; lines `57`-`62` create a generated `PROFILE=memmap` log when `INPUT_SERIAL_LOG` is unset; line `94` reports pass using the chosen file. This is acceptable as a fixture smoke, but it is not equivalent to guest serial evidence for Laws 2, 3, or 8.

2. **WARNING - TempleOS fixture rows look like Book-of-Truth rows but carry only comment-level fixture provenance.**
   Evidence: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/gen-bookoftruth-log-fixture.sh:149`-`150` writes `# fixture_profile=` and `# deterministic=1`; lines `157`-`159` then emit normal-looking `BOT seq=... payload=... prev=... hash=...` rows. A downstream parser that ignores comments cannot tell generated replay rows from guest serial rows.

3. **WARNING - TempleOS mem-map smoke checks hook presence, not Law 8 hardware-proximity semantics.**
   Evidence: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/bookoftruth-memmap-smoke.sh:48`-`54` only greps for `BookTruthMemMapRecord` and op IDs. In `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/Mem/MemPhysical.HC:117`-`123`, the `Mem64DevAlloc` PTE loop mutates page tables and invalidates pages before one aggregate `BookTruthMemMapRecord`. That may be intentional aggregation, but the current smoke cannot prove Law 8's "inline with the PTE modification" requirement.

4. **WARNING - holyc-inference North Star names a reference script whose default fixture is not committed.**
   Evidence: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/NORTH_STAR.md:16`-`18` requires bit-exact output matching `tests/reference_q4_gpt2.py`; `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/reference_q4_gpt2.py:23` points to `tests/fixtures/reference_q4_gpt2.json`. That file is absent at current head, and `python3 /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/reference_q4_gpt2.py` returned `ERROR: fixture not found at .../tests/fixtures/reference_q4_gpt2.json`.

5. **WARNING - holyc-inference reference capture is under-specified for offline, auditable provenance.**
   Evidence: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/reference_q4_gpt2.py:47`-`60` runs `--capture-cmd` with `shell=True`; lines `123`-`137` persist the raw command and optional excerpt, but lines `150`-`157` omit `source`, `capture_cmd`, and `capture_excerpt` from `--emit-json`. This drifts from `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/README.md:104`-`109` and `139`-`143`, which require deterministic fixture artifacts, committed sidecars, no model downloading, and no networking or remote fixture fetches.

## Impact

This is a cross-repo auditability gap, not evidence that networking was enabled or the TempleOS guest was run unsafely. The risk is that future gates may compare TempleOS synthetic serial replay output and holyc-inference model-reference output as if both were equally authoritative truth, even though their provenance is currently asymmetric.

## Recommendations

- Add a shared fixture provenance contract for both repos: `synthetic_fixture`, `source_class`, `generator`, `generator_commit`, `artifact_sha256`, `input_sha256`, `capture_cmd_sha256`, `network_forbidden`, and `guest_airgap_proof`.
- Make TempleOS replay smokes print `evidence_class=synthetic-fixture` unless `INPUT_SERIAL_LOG` is supplied, and require live/guest evidence reports to reject synthetic logs.
- Add the missing holyc-inference `tests/fixtures/reference_q4_gpt2.json` or change North Star tooling to fail with a specific "reference not established" status.
- Make `tests/reference_q4_gpt2.py --emit-json` include provenance fields, and reject capture commands that are not explicitly local/offline.
- Extend TempleOS mem-map validation beyond symbol greps to check proximity expectations for PTE writes versus Book-of-Truth records.
