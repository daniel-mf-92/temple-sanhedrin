# Enforcement idempotency: repeated same-SHA detections

Trigger: `audits/enforcement.log` shows repeated `LAW-4-compounding` detect/already-clean entries for the same SHA (`6c0c561...`) across consecutive iterations.

Online note checked:
- Idempotent automation guidance emphasizes recording processed state and short-circuiting repeat runs to avoid duplicate side effects and noisy loops.

Actionable fix pattern for Sanhedrin loop:
- Persist a processed-key state file (repo+sha+law+detail hash) in `automation/logs/`.
- Before reporting/acting, skip if key already processed in the last N hours and working tree is clean for that target.
- Log one `dedup-skip` line instead of repeating `DETECT`/`ALREADY-CLEAN` pairs.
- Add test: feed same violating commit twice and assert second pass emits only `dedup-skip`.
