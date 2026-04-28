# Law 4 Post-Rule Regression Backfill

Timestamp: 2026-04-28T13:28:01+02:00

Scope: compliance backfill for the later `LAWS.md` rule titled "Law 4 -- Identifier Compounding Ban", limited to commits from the rule-introduction commit through current HEAD in `TempleOS` and `holyc-inference`.

Inputs:
- TempleOS repo: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS`
- holyc-inference repo: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference`
- TempleOS rule-introduction commit: `5e92e74c8c1b1b92377c821a93feb24cf89adf42`
- holyc-inference rule-introduction commit: `d433483b80a0d1beb4e7598503d42fe51d643b1e`
- TempleOS HEAD scanned: `e868ba65878b282ff5b2d2464b6bd95cb56e6c76`
- holyc-inference HEAD scanned: `ce09228422dae06e86feb84925d51df88d67821b`

Method:
- Read-only git history scan; no trinity source files were modified.
- No QEMU or VM commands were executed.
- Scored added/modified files per commit for the measurable Law 4 limits: basename without extension longer than 40 characters, basename with more than 5 hyphen/underscore tokens, and added function-like identifiers in `.HC`, `.sh`, and `.py` longer than 40 characters.
- Included the rule-introduction commits themselves because the rule should be self-consistent at the point of adoption.
- Separately ran each repo's current `automation/check-no-compound-names.sh HEAD`; both current HEAD checks returned OK.

## Executive Summary

Finding count: 6

| Repo | Commits scanned | Violating commits | Clean commits | Compliance score | Mechanical violations |
| --- | ---: | ---: | ---: | ---: | ---: |
| TempleOS | 44 | 6 | 38 | 86.4% | 14 |
| holyc-inference | 23 | 16 | 7 | 30.4% | 91 |
| Combined | 67 | 22 | 45 | 67.2% | 105 |

Violation type totals:

| Repo | Filename length | Filename tokens | Identifier length |
| --- | ---: | ---: | ---: |
| TempleOS | 6 | 6 | 2 |
| holyc-inference | 13 | 14 | 64 |
| Combined | 19 | 20 | 66 |

## Findings

### 1. CRITICAL: holyc-inference kept regressing after the ban

`holyc-inference` has 16 violating commits out of 23 scanned from the rule-introduction point through HEAD. That is a 30.4% post-rule compliance score, with 91 total mechanical violations. Most hits are added identifier names over 40 characters in runtime-adjacent HolyC and Python parity tests.

Highest-impact commits:
- `9e836f893b7f486cea81f4f609ca54ba4dee2d0b`: 18 violations, including GPU security/perf identifiers up to 252 characters.
- `a609e085bcdef3d14f451566cf4fbae93396cbf8`: 13 violations, including fixed-point identifiers up to 68 characters and committed `__pycache__` artifacts.
- `973bf85029efe85cc35890897e3f9faf5eb5b4b4`: 8 identifier violations around Book of Truth token event tests.

### 2. WARNING: TempleOS improved, but still had post-rule regressions

`TempleOS` has 6 violating commits out of 44 scanned from the rule-introduction point through HEAD. That is materially better than the pre-rule trend, but the rule-introduction commit itself and later modernization commits still created 14 mechanical violations.

Highest-impact commits:
- `5e92e74c8c1b1b92377c821a93feb24cf89adf42`: 4 violations in the commit that introduced the ban.
- `c6b70f17ede58ab3ba5906941a655c4fb8a26002`: 2 identifier-length violations in `Kernel/Sched.HC`.
- `6c0c561670637e945fb61064b283a7838a96f147` and `848ec838a3e173390df8fb6d65304873fe381a49`: long automation filename regressions later removed by Sanhedrin enforcement commits.

### 3. CRITICAL: The rule-introduction commit was not self-clean in TempleOS

The TempleOS rule-introduction commit added or modified these violating paths:
- `automation/sched-lifecycle-invariant-window-code-cq-depth-check.sh`: basename length 52, token count 8.
- `automation/sched-lifecycle-invariant-window-code-cq-depth-check.sh.deprecated.bak`: basename length 66, token count 8.

This means Law 4 enforcement started with a known inconsistent baseline in TempleOS. Backfill scoring should treat the introduction point as a violation, not just as a boundary.

### 4. WARNING: Committed generated Python cache files inflated holyc-inference violations

Several holyc-inference violations came from committed `tests/__pycache__/*.pyc` paths. Examples include:
- `tests/__pycache__/test_gpu_security_perf_fast_path_switch_batch_audit_q64_iq1782.cpython-314-pytest-9.0.3.pyc`: basename length 87, token count 14.
- `tests/__pycache__/test_iq1796_bot_pre.cpython-314-pytest-9.0.3.pyc`: basename length 44, token count 7.

Generated caches are not core runtime implementation code, but committing them weakens Law 4 signal quality and creates avoidable revert churn.

### 5. WARNING: Current HEAD checks are clean but only prove the latest diff

Both repos currently pass `bash automation/check-no-compound-names.sh HEAD`. That is useful for current-iteration gating, but it does not mean post-rule history is clean. The backfill found 22 violating commits between rule adoption and current HEAD even though both latest commits pass.

### 6. INFO: Sanhedrin enforcement appears to be reducing TempleOS recurrence

TempleOS has enforcement commits after the `6c0c561` and `848ec83` regressions:
- `f140a8ab65e67b7acf3c4f44d00f650ee1512d6a`: removed Law 4 violators introduced by `6c0c561670637e945fb61064b283a7838a96f147`.
- `3812751b6a48cb0fb18e8f3ac3e10f213d56a5ef`: removed Law 4 violators introduced by `848ec838a3e173390df8fb6d65304873fe381a49`.

That pattern is less visible in holyc-inference, where most post-rule commits in this window still violated the measurable naming subset.

## Post-Rule Violating Commits

TempleOS:

| Commit | Date | Violations | Dominant evidence |
| --- | --- | ---: | --- |
| `5e92e74c8c1b1b92377c821a93feb24cf89adf42` | 2026-04-27T15:43:12+02:00 | 4 | Rule-introduction automation filenames |
| `a938842f704f63437dd5c92dd5f850d744c5a07f` | 2026-04-27T15:58:15+02:00 | 2 | Long sched lifecycle helper filename |
| `a4548151871cc54104179dafdd7d889d9c3cec1e32` | 2026-04-27T16:05:18+02:00 | 2 | Reintroduced long helper filename via revert |
| `c6b70f17ede58ab3ba5906941a655c4fb8a26002` | 2026-04-27T16:28:48+02:00 | 2 | Long `Kernel/Sched.HC` identifiers |
| `6c0c561670637e945fb61064b283a7838a96f147` | 2026-04-28T04:14:12+02:00 | 2 | Long automation filename |
| `848ec838a3e173390df8fb6d65304873fe381a49` | 2026-04-28T06:29:58+02:00 | 2 | Long automation filename |

holyc-inference:

| Commit | Date | Violations | Dominant evidence |
| --- | --- | ---: | --- |
| `9e836f893b7f486cea81f4f609ca54ba4dee2d0b` | 2026-04-27T16:01:35+02:00 | 18 | GPU security/perf chained identifiers and cache paths |
| `9d34b45341497be3f8258388c44adf536026d15c` | 2026-04-27T16:04:29+02:00 | 4 | Committed `__pycache__` artifacts |
| `a2e460b02962faac6b2876ac156078ecb0c69db2` | 2026-04-27T16:32:05+02:00 | 2 | Reintroduced cache artifact via revert |
| `12d6fe3b7a105ef22ccd980a21bac66252d7f92e` | 2026-04-27T16:33:26+02:00 | 4 | Book of Truth token event identifiers/tests |
| `973bf85029efe85cc35890897e3f9faf5eb5b4b4` | 2026-04-27T16:45:19+02:00 | 8 | Book of Truth token event identifiers/tests |
| `a609e085bcdef3d14f451566cf4fbae93396cbf8` | 2026-04-27T17:00:17+02:00 | 13 | Fixed-point chained identifiers and cache path |
| `f4d1f3f3feeb81a433d21ac204b88690d1a13905` | 2026-04-27T17:22:13+02:00 | 8 | Book of Truth preflight/parity identifiers |
| `190c103d26a45cd9661d59e186730128b721e905` | 2026-04-27T17:36:06+02:00 | 4 | Long parity test names |
| `1267789846543c4ea188e3b3e027006f04bb20c6` | 2026-04-27T18:11:34+02:00 | 4 | Committed `__pycache__` artifacts |
| `898aa2a5b5e82152819bd97150ace73dd81cb6ba` | 2026-04-27T18:29:47+02:00 | 4 | Long diagnostics test names |
| `ff85174101ff2fde82c72a99174adcc029298cee` | 2026-04-27T18:45:11+02:00 | 8 | Cache paths and long diagnostics test names |
| `6f5e1f5b4e1b200b81d0e0f0a3b31c03073f7c6a` | 2026-04-27T19:11:21+02:00 | 4 | Long commit test names |
| `1c5586ad9c802dd1f08196eb913df76448fddadb` | 2026-04-27T19:29:13+02:00 | 4 | Long preflight test names |
| `ea708d796a8c7572bdbef9ede31ffe0a482942a7` | 2026-04-27T21:03:05+02:00 | 2 | Committed cache path |
| `feab9a982d17fb6c2e89f1abc111dd5bd5c98647` | 2026-04-27T21:49:56+02:00 | 2 | Long deterministic secure test name |
| `b8a4fc8b7dd7cb2175ff3e4e8f051a7d4b19ca7d` | 2026-04-27T22:36:11+02:00 | 2 | Long deterministic parity test name |

## Recommendation

Keep Law 4 enforcement active, but tighten two audit paths:
- Score the rule-introduction commit when backfilling any newly added rule; adoption commits must be self-clean.
- Add generated-cache detection to Law 4 reports so committed `__pycache__` artifacts are reported as avoidable hygiene violations instead of blending into source identifier trends.
