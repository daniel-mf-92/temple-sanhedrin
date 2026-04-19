# IQ-451 stuck pattern: integer exp range-reduction hardening

Trigger: `inference` repeated `IQ-451` 3 times in recent window.

Findings (actionable):
- Keep fdlibm-style decomposition (`x = k*ln2 + r`) but enforce deterministic tie-breaks at half-way boundaries to prevent oscillating retries.
- Add a single canonical no-partial API path and route wrappers to it to avoid repeated churn on semantics.
- Use table-driven correction terms for `ln2_hi/ln2_lo` (or equivalent fixed-point split constants) and test boundary vectors around every `k` transition.
- Add property tests for monotonicity and symmetry around zero in fixed-point domain to catch regressions before queue repeats.

References:
- https://netlib.org/fdlibm/
- https://github.com/freemint/fdlibm/blob/master/e_exp.c
- https://github.com/cloudius-systems/musl/blob/master/src/math/exp.c
