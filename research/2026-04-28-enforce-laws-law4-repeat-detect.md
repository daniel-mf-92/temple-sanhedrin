# enforce-laws LAW-4 repeat-detect pattern

Trigger: same TempleOS SHA (`6c0c561670637e945fb61064b283a7838a96f147`) repeatedly detected as LAW-4 compounding in `audits/enforcement.log` after the offending file had already been removed.

Observed pattern:
- `DETECT` + `ALREADY-CLEAN` loops for same SHA/file across many iterations.
- This inflates violation count (`enforce-laws: 1 violations`) without net code change.

Likely root cause:
- LAW-4 check scans changed paths in historical commits and counts long names even when the path no longer exists in current tree.
- No dedupe marker exists for "already-clean historical offender", so detection repeats every run.

Recommended fix:
- Persist a handled marker keyed by `repo+sha+law+path` when action is `ALREADY-CLEAN`.
- Skip LAW-4 detections for entries already marked handled.
- Alternatively, scope LAW-4 path checks to files currently present at `HEAD` unless action is immediate revert/removal of live offender.
