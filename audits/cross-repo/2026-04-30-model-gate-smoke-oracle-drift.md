# Cross-Repo Audit: Model Gate Smoke Oracle Drift

Date: 2026-04-30T03:38:31+02:00

Scope: cross-repo invariant check between `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `9cda3b1fa3ad220a704c6b88ef1b671db9602547` and `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `2799283c9554bea44c132137c590f02034c8f726`.

This audit was read-only against TempleOS and holyc-inference. It did not run QEMU, did not start a VM, did not inspect live loop liveness, did not execute any WS8 networking task, and did not modify trinity source code. The only executable check was a host-side grep smoke script with `REPO_DIR` explicitly pointed at the local TempleOS tree.

## Question

Does TempleOS' model-gate smoke oracle still match the Book-of-Truth model gate status surface that holyc-inference depends on for secure-local model promotion evidence?

Short answer: no. TempleOS' implementation has evolved to include deterministic-gate counters in `BookTruthModelGateStatus`, but the smoke oracle still checks the older status format. That makes the TempleOS model gate evidence surface look red even when the implementation includes more useful deterministic fields, and it weakens cross-repo promotion accounting because holyc-inference needs parser/eval/model-gate proof to converge with TempleOS.

## Findings

1. WARNING: TempleOS' model-gate smoke oracle is stale.
   - Evidence: `automation/bookoftruth-model-gate-smoke.sh:35` requires the exact older string `BookTruthModelGateStatus: rows=%d profile_evt=%d secure=%d dev=%d promote_evt=%d promote_ok=%d promote_gate=%d import_bad=%d verify_fail=%d last_model=%d last_gate=%X last_seq=%d`.
   - Evidence: `Kernel/BookOfTruth.HC:13147-13150` emits the newer string with `det_evt=%d det_ok=%d det_fail=%d` inserted before `last_model`.
   - Evidence: `REPO_DIR=/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS bash automation/bookoftruth-model-gate-smoke.sh` exits with `rc=1` and reports `model gate status output missing`.
   - Impact: a valid implementation can fail the host smoke because the oracle is matching an obsolete literal, not the current evidence schema.

2. WARNING: deterministic-gate evidence is present in the status output but absent from the smoke's acceptance criteria.
   - Evidence: `Kernel/BookOfTruth.HC:13075-13090` initializes `det_evt`, `det_ok`, and `det_fail`; `Kernel/BookOfTruth.HC:13125-13131` counts `BOT_MODEL_MARK_DET` records as deterministic gate pass/fail events.
   - Evidence: the smoke script never checks `BOT_MODEL_MARK_DET`, `det_evt`, `det_ok`, or `det_fail`.
   - Impact: TempleOS can regress deterministic-gate accounting while still satisfying the old smoke after a string-only update, unless the oracle is changed to assert the new fields semantically.

3. WARNING: holyc-inference's secure-local policy expects parser/eval hardening to be promotion evidence, but the TempleOS smoke failure makes that evidence unreliable to consume automatically.
   - Evidence: holyc-inference `MASTER_TASKS.md` defines secure-local promotion requirements for deterministic evaluation and parser hardening under WS16-04 and WS16-05.
   - Evidence: TempleOS `BookTruthModelGateStatus` now tries to summarize deterministic gate rows, but the current smoke gate fails before Sanhedrin or other automation can treat the surface as healthy.
   - Impact: cross-repo release tooling may either ignore TempleOS model-gate evidence because the smoke is red, or bypass the smoke and accept unverified strings manually. Both paths reduce confidence in Law 5 north-star progress accounting.

4. INFO: this is not a LAWS.md source violation.
   - No non-HolyC core implementation was added by this audit, no guest networking was touched, no VM command was run, and the issue is an executable-evidence drift between a TempleOS host smoke script and its current Book-of-Truth status surface.

## Required Closure

- Update `automation/bookoftruth-model-gate-smoke.sh` to accept and assert the current `det_evt`, `det_ok`, and `det_fail` fields.
- Prefer field-level checks over one exact long format string so future append-only status extensions do not break the oracle.
- Add a fixture or parser check that proves `BOT_MODEL_MARK_DET` pass/fail rows affect `BookTruthModelGateStatus` counters.
- Treat model promotion evidence as incomplete unless the same report includes TempleOS parser-gate, deterministic-gate, and append-proof fields that holyc-inference can join to its trusted manifest/quarantine state.

## Evidence Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/bookoftruth-model-gate-smoke.sh | sed -n '1,90p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC | sed -n '13070,13160p'
REPO_DIR=/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS bash /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/bookoftruth-model-gate-smoke.sh
rg -n "WS16-04|WS16-05|deterministic evaluation|parser hardening|Book-of-Truth" /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md
```
