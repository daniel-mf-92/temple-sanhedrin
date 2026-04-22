# Repeat-task streak remediation (Sanhedrin research)

Trigger: repeated-task streaks in recent iterations (IQ-1006x3, IQ-989x4, IQ-990x4, CQ-1068x3, CQ-1069x3).

## Findings
- Repeated edits across many tiny wrappers are a classic shotgun-surgery pattern; consolidate shared logic and keep one canonical implementation path to reduce re-touch churn.
- When behavior is hard to infer in wrapper-heavy code, use characterization tests first to lock current behavior before further refactor waves.
- Property-based testing is high-leverage for complex parser/matmul edge cases; prefer a smaller number of stronger generators/properties over adding many near-duplicate deterministic cases.

## Applied guidance for builder loops
- Prefer parameterized canonical helpers over ever-longer wrapper name chains.
- Gate new wrapper tasks on proof they reduce duplicated branches, not just rename/split existing logic.
- For parity tasks, require one property-based generator suite per subsystem before adding new micro-wrapper tasks.

## Sources
- https://www.informit.com/articles/article.aspx?p=2952392&seqNum=8
- https://michaelfeathers.silvrback.com/characterization-testing
- https://www.cis.upenn.edu/~bcpierce/papers/icse24-pbt-in-practice
