# Retroactive Commit Audit: Law 4 / Law 6 Recent Window

Timestamp: 2026-04-27T14:12:37Z
Scope: recent commit window across read-only trinity repos:
- TempleOS: `a5dc52a`, `a454815`, `1370d9c`, `a938842`, `5e92e74`, `f702ec1`
- holyc-inference: `9d34b453`, `9e836f89`, `d433483b`, `2929f5ef`, `58cdb5e5`, `259b9e08`

Method:
- Read `LAWS.md` from temple-sanhedrin.
- Inspected `git show --name-status` and selected diffs for each commit.
- Ran `automation/check-no-compound-names.sh <sha>` from each target repo as corroborating evidence.
- Searched added diff lines for QEMU/network, float, Book-of-Truth, CQ/IQ, and generated-cache markers.
- Did not modify TempleOS or holyc-inference source code.

Findings count: 15

Findings:
- TempleOS `a454815`: CRITICAL Law 4, reintroduced 87-character / 11-token automation filename.
- TempleOS `a454815`: WARNING Law 6, reintroduced new CQ queue lines in a revert-of-enforcement commit.
- TempleOS `a938842`: CRITICAL Law 4, added 87-character / 11-token automation filename.
- TempleOS `a938842`: WARNING Law 6, added CQ queue lines during a builder iteration.
- TempleOS `5e92e74`: WARNING Law 4, introduced compounding enforcement while retaining long legacy automation filenames and `.bak` name.
- TempleOS `f702ec1`: CRITICAL Law 4, added 95-character / 14-token automation filename.
- TempleOS `f702ec1`: WARNING Law 6, added CQ queue lines during a builder iteration.
- holyc-inference `9d34b453`: CRITICAL Law 4, committed long compound generated `__pycache__` filenames.
- holyc-inference `9d34b453`: WARNING Law 5, checkpoint committed only compiled cache artifacts.
- holyc-inference `9e836f89`: CRITICAL Law 4, added 200+ character HolyC identifiers and long compound test/cache filenames.
- holyc-inference `9e836f89`: WARNING Law 6, added a new IQ queue line.
- holyc-inference `2929f5ef`: CRITICAL Law 4, added long compound test/cache filenames and long test identifier.
- holyc-inference `2929f5ef`: WARNING Law 6, added a new IQ queue line.
- holyc-inference `58cdb5e5`: CRITICAL Law 4, added a 204-character HolyC identifier and long compound test/cache filenames.
- holyc-inference `259b9e08`: WARNING Law 6, added a new IQ queue line while extending the compounding chain.

Negative checks:
- QEMU/network-related added lines in this window either documented or enforced `-nic none` / `-net none`; no Law 2 breach was observed.
- Non-HolyC Python additions were host-side tooling or tests, not core subsystem/runtime implementation; no Law 1 breach was counted for those files.
- holyc-inference `d433483b`, TempleOS `a5dc52a`, and TempleOS `1370d9c` were not flagged in this window.

Auditor note:
- `automation/check-no-compound-names.sh <historical-sha>` skips files absent from the current worktree, so it can miss historical commits that added long filenames later deleted by reverts. This affected TempleOS `a938842` and `a454815`; manual `git show --name-status` evidence caught the violations.
