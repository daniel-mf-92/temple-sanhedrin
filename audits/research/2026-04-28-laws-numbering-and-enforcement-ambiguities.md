# Deep LAWS Research: Numbering and Enforcement Ambiguities

Timestamp: 2026-04-27T23:04:40Z

Auditor: gpt-5.5 sibling, retroactive/deep research scope

Audit angle: deeper `LAWS.md` research and edge-case analysis. No TempleOS or holyc-inference source code was modified. No VM/QEMU command was executed.

Repos examined:
- TempleOS committed HEAD: `06e0e74851510affb8c005f70aa3fbdc400ed79a`
- holyc-inference committed HEAD: `bf852f741851fbcec5c44e30b76e8b89d23faa5d`
- temple-sanhedrin baseline: `0a2afe4d2af2f7bbad82d0bbc99e0c9beee6a594`
- temple-sanhedrin branch: `codex/sanhedrin-gpt55-audit`

## Executive Summary

Found 6 findings: 2 critical ambiguities, 3 warnings, 1 info.

The current `LAWS.md` mixes the original 1-11 law set with later appended rules that reuse Law 4, Law 5, Law 6, and Law 7. That makes audit reports and enforcement logs ambiguous: "Law 4" can mean integer-only inference runtime or identifier compounding, "Law 6" can mean queue health or no self-generated queue items, and "Law 7" can mean process liveness or blocker escalation. The enforcement script currently logs appended-rule names as `LAW-4-compounding`, `LAW-6-self-queue`, and `LAW-7-repeated-blocker`, but those ids are not canonicalized in `LAWS.md` itself.

The deeper issue is semantic drift between written doctrine and measurable enforcement. Several later rules have hard revert language, but the script only enforces the last-five commits on selected loop branches and only implements a subset of the written checks. This is not a builder-code violation; it is an audit doctrine risk that can cause false confidence and inconsistent retroactive findings.

## Finding CRITICAL-001: Law numbers are reused for distinct rules

Applicable surface:
- `LAWS.md:47-58` defines Law 4 as Integer Purity for the inference agent.
- `LAWS.md:181-189` defines another Law 4 as Identifier Compounding Ban for both builder agents.
- `LAWS.md:60-84` defines Law 5 and Law 6 as No Busywork and Queue Health.
- `LAWS.md:191-197` reuses Law 5 and Law 6 for North Star Discipline and No Self-Generated Queue Items.
- `LAWS.md:86-94` defines Law 7 as Process Liveness.
- `LAWS.md:199-201` reuses Law 7 for Blocker Escalation.

Assessment:
This is the highest-risk ambiguity because findings, enforcement logs, and revert messages frequently cite only a law number. A historical report that says "Law 4 violation" is not self-contained unless it also names the rule title. Worse, "Law 6" can mean either queue depth health or queue self-padding, which can imply opposite remediations.

Recommended refinement:
- Assign stable ids that never reuse numbers, for example `LAW-04-INTEGER`, `LAW-12-NAME-COMPOUNDING`, `LAW-13-NORTH-STAR`, `LAW-14-NO-SELF-QUEUE`, and `LAW-15-BLOCKER-ESCALATION`.
- Keep the old numbers as aliases only in a migration table.
- Require every audit report and enforcement log line to include both stable id and title.

## Finding CRITICAL-002: Written enforcement promises exceed implemented enforcement

Applicable surface:
- `LAWS.md:188-189` says identifier compounding is detected with `automation/check-no-compound-names.sh HEAD` and enforced by Sanhedrin reverts.
- `LAWS.md:197` says self-padding the queue is grounds for revert.
- `automation/enforce-laws.sh:43-44` only inspects the last 5 commits on a selected active branch.
- `automation/enforce-laws.sh:54-75` implements filename length/token checks directly, not the full builder-side checker contract.
- `automation/enforce-laws.sh:77-88` only detects added unchecked CQ/IQ lines in `MASTER_TASKS.md`.

Assessment:
The law text reads like full enforcement, but the script is a recent-commit guard. Historical/backfill audits have already found broader violations than the live script can catch. This creates a doctrine gap: a commit outside the last-five window, a non-selected branch, or a violation missed by the simplified script can be described as "enforced" by policy while never actually being reverted.

Recommended refinement:
- Split each law into `Rule`, `Detection`, `Live enforcement`, and `Backfill enforcement` sections.
- State explicitly that current automated reverts are bounded to the last N commits unless a wider sweep is run.
- Require enforcement scripts to print their coverage window in the log.

## Finding WARNING-001: Identifier compounding's "existing-name + suffix" clause is not measurable in current checkers

Applicable surface:
- `LAWS.md:186` forbids names that are existing-name plus suffix.
- TempleOS `automation/check-no-compound-names.sh:21-34` checks filename length and hyphen/underscore token count.
- TempleOS `automation/check-no-compound-names.sh:36-52` checks only added function-like identifiers longer than 40 characters.
- holyc-inference has the same checker shape at `automation/check-no-compound-names.sh:21-52`.

Assessment:
The "existing-name + suffix" clause is valuable, but currently undefined: it does not specify ancestor window, similarity threshold, allowed wrapper names, or whether semantic suffixes such as `Checked`, `Default`, `NoPartial`, and `PreflightOnly` are always suspect. Auditors can only enforce it by judgment, which makes retroactive scoring inconsistent.

Recommended refinement:
- Define a measurable suffix-chain rule, such as "a new identifier may not equal an existing identifier plus one terminal token unless listed in an allowed suffix table."
- Add an allowlist for intentionally meaningful suffixes and require a contract comment when more than one suffix is stacked.
- Teach the checker to compare added identifiers against parent-tree identifiers, not only length.

## Finding WARNING-002: Scope boundaries for host-side automation versus core implementation need a per-law matrix

Applicable surface:
- `LAWS.md:23-25` allows host-side tooling in `automation/`, `tests/`, and `.github/`.
- `LAWS.md:27-35` forbids network-dependent package managers or build steps under the air-gap law.
- `LAWS.md:140-149` requires QEMU OS-image drives to use `readonly=on`.
- `LAWS.md:151-159` forbids Book-of-Truth export paths, including serial output forwarding and print-to-file access.

Assessment:
The general host-side exception for Law 1 does not imply exceptions for Laws 2, 10, or 11, but `LAWS.md` does not state that explicitly. This matters because most QEMU, serial, and benchmark surfaces are host-side automation. A builder can reasonably read the Law 1 exception as making host scripts broadly permissive, while later laws intentionally constrain host scripts when they launch or observe a TempleOS guest.

Recommended refinement:
- Add a short scope matrix: core code, host automation, tests, docs, and generated artifacts versus each law.
- State that the Law 1 host-tooling exception is only a language exception, not an air-gap, immutable-image, or Book-of-Truth export exception.
- Require QEMU/serial host tooling to classify runs as compile-only, Book-of-Truth-bearing, or guest-runtime-bearing.

## Finding WARNING-003: "Active hours" and liveness ownership are underspecified for retroactive audits

Applicable surface:
- `LAWS.md:86-94` requires both loops to run, heartbeat freshness within 10 minutes, and at least one commit in the last 30 minutes during active hours.
- The user scope for this sibling explicitly excludes live liveness watching and current-iteration audit.

Assessment:
For the gpt-5.5 sibling, live liveness checks are out of scope, but Law 7 still appears in the same law file as retroactive obligations. The doctrine needs a distinction between live Sanhedrin responsibilities and historical audit responsibilities. Otherwise, a retroactive report can look incomplete for not checking a live process it is forbidden to watch.

Recommended refinement:
- Add an "auditor role scope" section that maps live Sanhedrin, retroactive sibling, and builders to allowed checks.
- Define "active hours" with timezone and exceptions, or require reports to cite the schedule source used.
- Require retroactive Law 7 audits to use historical heartbeat/log evidence only, not current process watching.

## Finding INFO-001: The written air-gap and HolyC-only safety requirements are directionally clear

Applicable surface:
- `LAWS.md:13-35` states HolyC-only core implementation and explicit no-network QEMU/VM requirements.
- The current user safety requirements also restate that WS8 networking tasks are out of scope and QEMU/VM commands must use `-nic none` or `-net none`.

Assessment:
Despite numbering drift, the two most safety-critical doctrine points are clear enough for audit use: TempleOS guest networking remains forbidden, and core TempleOS modernization remains HolyC-only. This research did not find a need to weaken either requirement. The needed change is identifier stability and scope precision, not policy relaxation.

## Proposed LAWS.md Patch Shape

Do not apply automatically from this audit; this is a research recommendation for a future human-reviewed doctrine change.

```text
## Stable Law IDs

Each law has one immutable id. Old headings remain aliases only.

LAW-01-HOLYC-PURITY
LAW-02-AIR-GAP
LAW-03-BOT-IMMUTABILITY
LAW-04-INTEGER-RUNTIME
LAW-05-NO-BUSYWORK
LAW-06-QUEUE-HEALTH
LAW-07-PROCESS-LIVENESS
LAW-08-BOT-HARDWARE-PROXIMITY
LAW-09-BOT-FAIL-STOP
LAW-10-IMMUTABLE-OS-IMAGE
LAW-11-BOT-LOCAL-ACCESS
LAW-12-NAME-COMPOUNDING
LAW-13-NORTH-STAR
LAW-14-NO-SELF-QUEUE
LAW-15-BLOCKER-ESCALATION
```

## Issue Register

Opened local issue register: `audits/issues/2026-04-28-laws-ambiguity-issue-register.md`

Issues:
- ISSUE-LAWS-001: assign stable non-reused law ids.
- ISSUE-LAWS-002: document live versus backfill enforcement coverage.
- ISSUE-LAWS-003: define measurable suffix-chain detection for name compounding.
- ISSUE-LAWS-004: add host-tooling scope matrix for Laws 1, 2, 10, and 11.
- ISSUE-LAWS-005: define retroactive Law 7/liveness audit boundaries.

## Read-Only Verification Commands

- `nl -ba LAWS.md | sed -n '1,240p'`
- `nl -ba automation/enforce-laws.sh | sed -n '1,260p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/automation/check-no-compound-names.sh | sed -n '1,240p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/automation/check-no-compound-names.sh | sed -n '1,240p'`
- `git -C /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55 rev-parse HEAD`
- `git -C /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55 rev-parse HEAD`
- `git rev-parse HEAD`
