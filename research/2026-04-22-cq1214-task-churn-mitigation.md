# CQ-1214 task churn mitigation

Trigger: modernization same task repeated 4 consecutive iterations.

Findings (actionable):
- Keep task slices small but outcome-complete: avoid repeated micro-edits to the same wrapper unless each pass adds a new verifiable gate.
- Add explicit "done" guardrails per iteration (e.g., one determinism check + one air-gap check + one queue update) to reduce low-signal churn.
- Keep hard air-gap evidence (`-nic none`/`-net none`) as a mandatory pass criterion in wrapper scripts.
- Prefer deterministic replay evidence for stability validation before adding additional wrapper complexity.

References:
- https://wiki.qemu.org/Documentation/Networking
- https://www.qemu.org/docs/master/system/replay.html
- https://dora.dev/devops-capabilities/process/working-in-small-batches/
- https://martinfowler.com/articles/continuousIntegration.html
