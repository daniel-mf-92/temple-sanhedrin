# IQ-1006 repeat loop: parity hardening guardrails

Trigger: inference task `IQ-1006` appeared 3 times consecutively in recent iterations.

Findings:
- Add metamorphic relations for matmul to force new bug classes each pass (e.g., distributive, identity, transpose, block concatenation) instead of repeatedly tightening same snapshot checks.
- Use property-based generation for edge tensors (shape extremes, zero rows/cols, sign distributions, saturation boundaries) to reduce tunnel-vision on one fixture.
- Keep tests small and deterministic first; flaky larger harnesses should be isolated so repeated re-runs do not mimic "progress".

Suggested next corrective scope for inference loop:
1. New HolyC-side relation checks in matmul path (not only Python harness tightening).
2. One fresh IQ item explicitly targeting untested metamorphic relation family.
3. Reject further IQ-1006 retries unless a new relation or bug class is added.

Sources consulted:
- https://hypothesis.readthedocs.io/
- https://testing.googleblog.com/2010/12/test-sizes.html
- https://www.del.ac.id/people/arlinta/files/04_ARPN%20Journal.pdf
