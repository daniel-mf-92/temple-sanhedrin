# LAWS Clean-Run Enforcement Proof Ambiguity

Timestamp: 2026-04-30T05:52:03+02:00

Audit angle: deeper `LAWS.md` / North Star research.

Scope:
- Sanhedrin `LAWS.md` at current `codex/sanhedrin-gpt55-audit`.
- Sanhedrin `NORTH_STAR.md`.
- Sanhedrin `automation/enforce-laws.sh` and `automation/north-star-e2e.sh`.

No TempleOS or holyc-inference source files were modified. No QEMU/VM command, SSH command, WS8 networking task, networking command, package-manager command, or remote-runtime action was executed.

## Question

What counts as Sanhedrin "teeth" when there are no current builder violations to revert?

The written doctrine has two different proof models:

- `NORTH_STAR.md` says the e2e check should accept at least one enforcement action in the last 24h **or** explicit "no violations detected - clean run" lines.
- `automation/enforce-laws.sh` appends a `CLEAN` line when no violations are found.
- `automation/north-star-e2e.sh` counts recent enforcement-log rows, but also requires at least one `revert` entry ever.
- `LAWS.md` says Sanhedrin reverts identifier-compounding commits and queue self-padding commits, while repeated blockers are escalated rather than reverted.

The intended invariant appears to be:

> A clean run can prove the enforcement loop is active only after Sanhedrin has previously demonstrated it can revert a real violation, or after a non-destructive synthetic violation drill has exercised the revert path.

That invariant is reasonable, but it is not currently stated as doctrine. The result is ambiguity between "no violations detected" as a valid green state and "no revert ever" as a permanent red state.

## Findings

1. **WARNING - The written North Star allows clean-run proof, but the executable gate requires a historical revert.**
   Evidence: `NORTH_STAR.md` says the e2e condition is recent enforcement action or clean-run line, while `automation/north-star-e2e.sh` separately fails when `grep -c "revert" audits/enforcement.log` is below 1.
   Impact: a fully compliant day with no violations can still fail the North Star if no prior revert is logged. That may be intentional, but the doctrine should say so explicitly.

2. **WARNING - "Enforcement action" is not typed strongly enough for clean-run scoring.**
   Evidence: `automation/enforce-laws.sh` logs `DETECT`, `REVERT`, `PUSH-FAIL`, and `CLEAN` rows into the same file, while `automation/north-star-e2e.sh` first counts any recent row and then greps for the substring `revert` anywhere in the file.
   Impact: retroactive trend reports cannot distinguish a successful revert, a failed push after detection, a blocker escalation, and a clean no-op without parsing free-form detail text.

3. **WARNING - Repeated blocker enforcement is doctrinally not a revert, but the North Star phrase "detects and reverts violations" can imply revert coverage for it.**
   Evidence: `NORTH_STAR.md` lists repeated blockers in the detection set, while `automation/enforce-laws.sh` correctly escalates them to `audits/blockers-escalated.log` instead of attempting a commit revert.
   Impact: auditors can over-score blocker handling as "failed to revert" even though the safer action is escalation. The law should classify outcomes as `revert`, `escalate`, or `clean`.

4. **INFO - The current implementation encodes a useful two-phase maturity model.**
   Evidence: recent clean-run rows prove the loop is executing, while the ever-revert requirement proves authority has been exercised at least once.
   Impact: this should be preserved, but moved from implicit script behavior into explicit policy so historical audits can score it consistently.

## Proposed LAWS / North Star Refinement

Add a short enforcement-proof section:

```text
Enforcement proof states:
- `revert`: a concrete offending builder commit was reverted and pushed.
- `escalate`: a non-revertable violation or repeated blocker was written to a human-visible escalation log.
- `clean`: enforcement ran over its declared window and found no revertable violation.

North Star green requires either:
- at least one recent `revert` or `escalate` action, or
- a recent `clean` action plus a prior successful `revert` drill/action proving Sanhedrin has exercised revert authority.
```

Tighten `automation/enforcement.log` expectations:

```text
Each line should include `action=`, `repo=`, `sha=`, `law=`, `outcome=`, and `window=`.
`automation/north-star-e2e.sh` should count typed `action=REVERT` rows rather than grepping for the word `revert`.
```

## Local Issue Opened

See `audits/issues/2026-04-30-clean-run-enforcement-proof-issue.md`.

## Evidence Commands

- `sed -n '1,260p' automation/enforce-laws.sh`
- `sed -n '1,260p' automation/north-star-e2e.sh`
- `rg -n "enforce|revert|same error|blocker|compounding|self-generated" automation LAWS.md NORTH_STAR.md -S`
