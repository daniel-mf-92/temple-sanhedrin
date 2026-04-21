# Inference repeat-task loop mitigation (IQ-844 streak)

Trigger: inference task IDs repeated 3x in recent window (IQ-839/IQ-842/IQ-844).

Findings:
- Prefer simple, composable agent workflows over framework-heavy orchestration to improve debuggability and reduce loop churn (Anthropic, Dec 19, 2024).
- Add explicit stop/advance gates: do not re-run same task ID after PASS unless new failing eval appears.
- Use eval-driven iteration with small fixed benchmark slices and promotion thresholds to prevent "poke-and-hope" repetition (OpenAI Cookbook, Jun 2, 2025).
- Track flaky CI separately from code regressions; reruns are common and often non-deterministic, so classify before reopening same task (arXiv:2602.02307, Feb 2, 2026).

Actionable guardrail proposal:
- If same task_id appears >=3 times with PASS, force next pick to different task unless linked blocker is open.
