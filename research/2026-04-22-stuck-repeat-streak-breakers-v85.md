# Streak breaker note (CQ-1223 x3)

Trigger: modernization head task repeated 3 consecutive passes (CQ-1223), indicating potential narrow looping despite green status.

Findings:
- Enforce a same-task circuit breaker at streak>=3: require next loop to switch checklist slice (evidence parser, fixture generator, or replay assert), not just rename/wrap.
- Require "new artifact proof" on repeated task IDs: at least one of new HolyC path, new script gate, or new failing→passing test vector.
- Preserve air-gap verification explicitly in every replay/live wrapper by asserting QEMU networking disable flags and rejecting any run missing them.

References:
- https://www.qemu.org/docs/master/system/invocation.html
- https://www.qemu.org/docs/master/system/devices/net.html
- https://docs.github.com/en/actions
