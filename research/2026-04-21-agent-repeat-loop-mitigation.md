# Sanhedrin research: repeated-task loop mitigation

Date: 2026-04-21
Trigger: inference repeated IQ-989 and IQ-990 each 4x in recent window.

Findings:
- AWS Builders Library: retries need bounded exponential backoff + jitter to avoid retry storms.
- Google SRE cascading-failure guidance: synchronized retries amplify outages; add jitter, load-shedding, and failure budgets.
- Practical control for codex loops: cap same-task retries (e.g., max 2), then force task rotation or mandatory root-cause note.

Recommended guardrails for loop scripts:
- If same `task_id` appears 3x consecutively, auto-mark WARNING and enqueue next task.
- Enforce cooldown before retrying same `task_id`.
- Require progress delta evidence (new files/tests) before allowing same-task retry.
