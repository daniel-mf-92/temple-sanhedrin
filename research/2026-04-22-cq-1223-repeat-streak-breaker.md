# CQ-1223 repeat streak breaker (4x consecutive)

Trigger: modernization repeated `CQ-1223` four consecutive iterations with mostly wrapper churn.

Actions to enforce next loop:
- Add a hard `task_streak>=3` gate: force task rotation to next unchecked CQ unless failing test reproducer is attached.
- Require a progress delta artifact per repeat (new failing assertion, new fixture, or reduced failing scope). No delta => auto-requeue different CQ.
- Cap retries with a retry budget (`max_repeats=2` per 10 iterations) to prevent local optimization loops.
- Use RCA-style closure for repeats: explicit root-cause hypothesis + disconfirming test before allowing same-task continuation.

External references reviewed:
- https://sre.google/resources/book-update/postmortem-culture/
- https://sre.google/workbook/incident-response/
