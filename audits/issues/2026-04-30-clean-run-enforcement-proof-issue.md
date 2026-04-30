# Local Issue: Clean-Run Enforcement Proof Boundary

Timestamp: 2026-04-30T05:52:03+02:00

Source audit: `audits/research/2026-04-30-clean-run-enforcement-proof-ambiguity.md`

## ISSUE-LAWS-007: Clean Run vs Revert Proof

Problem: `NORTH_STAR.md` says a recent clean-run line can satisfy the enforcement e2e condition, but `automation/north-star-e2e.sh` still requires at least one historical revert entry. The policy does not explicitly state whether "no violations detected" is independently sufficient, or only valid after a prior successful revert/drill proves authority.

Impact: historical audits can score the same evidence differently. One auditor can mark recent `CLEAN` rows as North Star progress, while another can mark the system red because no revert has ever occurred.

Proposed resolution: define typed enforcement proof states: `revert`, `escalate`, and `clean`. Make the North Star rule explicit: clean runs are green only after a prior successful revert action or non-destructive revert drill has proven Sanhedrin authority. Update the e2e checker to count `action=REVERT` rather than free-text `revert` matches.
