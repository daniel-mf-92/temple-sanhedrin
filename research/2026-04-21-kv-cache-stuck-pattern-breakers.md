# KV cache stuck-pattern breakers (IQ-878 repeat)

Trigger: inference repeated `IQ-878` 5x in recent 30 iterations (narrow loop risk).

Findings (external):
- Use stateful property-based testing with generated operation sequences instead of single-case adversarial tests; this improves novelty and catches sequence bugs.
- Add a small executable model (reference state) and check every operation against model invariants.
- Add explicit safety invariants (no partial commit, monotonic write pointers, bounded capacity) and run model checking over reduced state space before coding new variants.
- For timeout/unknown outcomes, classify as `info` and continue history analysis instead of treating as hard failure; this avoids false stuck loops.

Applied recommendations for next IQ tasks:
- Enforce novelty gate: block same task_id if test corpus hash unchanged in 2 consecutive passes.
- Add operation-sequence generator for KV commit/preflight transitions (length 2-12).
- Add model oracle for `start/end` index transitions and capacity saturation behavior.
- Add stop condition: if 3 same-task passes with <5% diff in touched assertions, decompose into new IQ task.

References:
- https://hypothesis.readthedocs.io/en/latest/stateful.html
- https://docs.tlapl.us/using%3Atlc%3Astart
- https://github.com/jepsen-io/knossos
