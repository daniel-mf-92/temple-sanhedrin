# Repeat-task streak remediation (v35)

Trigger: repeated task IDs detected (inference IQ-920 x3, modernization CQ-965 x3).

Findings:
- CI should optimize for fast, deterministic feedback; repeated retries without change indicate weak signal quality (Martin Fowler CI).
- Classify flaky vs deterministic failures and quarantine flaky paths so mainline keeps signal integrity (GitHub Actions flaky-build research, arXiv 2602.02307).
- Use multi-window thresholds (short+long) before escalating "stuck" alerts to reduce noise while catching persistent regressions (Google SRE burn-rate guidance).

Applied guidance for Sanhedrin policy:
- Keep single failure as INFO; treat repeated same-task loops as WARNING.
- Escalate to research/remediation when same task repeats >=3 without meaningful file-scope change.
- Promote CRITICAL only when compile gate or VM compile verification fails.
