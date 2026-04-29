# Queue-empty + QEMU timeout pattern (2026-04-29)

Trigger:
- Modernization: 8 consecutive `queue empty — North Star not hit, awaiting human input` finals.
- Inference: 17 consecutive `queue empty — North Star not hit, awaiting human input` finals.
- Modernization finals still show `RED: QEMU timed out after 180s`.

Observed local facts:
- Heartbeats are fresh for all three loops.
- No policy-drift or secure-local/GPU isolation bypass found.
- Queue-floor rule is abolished; repeated queue-empty is now a legitimate terminal state until humans append new queue items.

External references (QEMU docs):
- QEMU invocation docs confirm CLI options are authoritative for headless/character/network setup.
- QEMU monitor docs confirm monitor channel separation and command-surface behavior.

Actionable guidance (human queue owner):
- Add new non-doc queue items that directly move North Star from RED to GREEN.
- Prioritize items that reduce `north-star-e2e` timeout risk (boot/serial readiness, deterministic exit conditions, timeout instrumentation).
- Keep TempleOS air-gapped (`-nic none`) while iterating on headless boot observability.
