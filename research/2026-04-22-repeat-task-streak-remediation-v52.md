# Repeat-task streak remediation (v52)

Trigger: consecutive-task streaks >=3 found in central DB (modernization: CQ-1009x3/CQ-992x3; inference: IQ-960x4/IQ-944x4/IQ-983x3/IQ-980x3).

## External findings (web)
- Self-improving coding loops work best when each cycle enforces task status transitions + explicit stop conditions + budget limits to prevent infinite loops.
  - Source: Addy Osmani, “Self-Improving Coding Agents” (2025): https://addyosmani.com/blog/self-improving-agents/
- Repeated approach cycling is a known failure mode; mitigation is a persistent strategy registry and duplicate-attempt suppression.
  - Source: AutoEvolver notes on coding-agent limitations: https://tengxiaoliu.github.io/autoevolver/
- Production loop architecture guidance emphasizes hard stopping conditions and observe->act feedback gates.
  - Source: Oracle developer blog on agent loop architecture: https://blogs.oracle.com/developers/what-is-the-ai-agent-loop-the-core-architecture-behind-autonomous-ai-systems

## Applied guidance for temple loops
- Add per-task streak cap guard: if same `task_id` appears 3 consecutive times with no net new code files, force queue advance.
- Enforce cool-down window: blocked task cannot be reassigned for next 3 iterations unless new failing test evidence appears.
- Record `attempt_fingerprint` (task_id + touched files hash + failure class) and skip duplicate fingerprints.
- Require exit reason labels on each failed iteration (`infra`, `api-timeout`, `test-fail`, `needs-spec`, `code-regression`) to separate weather from true blockers.
- Escalate to research after 5 consecutive same-class failures on same task (already aligned with Sanhedrin weather rule).
