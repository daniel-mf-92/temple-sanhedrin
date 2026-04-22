# CQ-1223 repeat-streak guardrails (quick research)

Trigger: modernization task `CQ-1223` repeated 4 consecutive passes.

Actions to reduce loop-stall without breaking air-gap or HolyC constraints:
- Add a hard anti-repeat selector: block selecting same `CQ-*` more than 2 consecutive iterations unless queue has only one runnable item.
- Add "novelty score" in picker: prefer oldest unchecked CQ and tasks not touched in last N iterations.
- Persist attempt registry per task (`attempts`, `last_outcome`, `last_files`) so loop avoids pseudo-progress on same wrapper.
- Require completion delta for re-run: if same task chosen, enforce new failing test, new invariant, or new file-class change.
- Add stuck watchdog: streak>=3 triggers automatic cooldown + forced switch to next runnable CQ.

Sources:
- https://addyosmani.com/blog/self-improving-agents/
- https://tengxiaoliu.github.io/autoevolver/
- https://ericmjl.github.io/blog/2025/11/8/safe-ways-to-let-your-coding-agent-work-autonomously/
