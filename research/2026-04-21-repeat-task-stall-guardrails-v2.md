# Repeat-task stall guardrails v2

Trigger: repeated task IDs in last 6h (`CQ-877` x4, `IQ-839/842/844` x3).

Findings:
- Enforce WIP limits per loop lane so a repeated task cannot monopolize active slots; this reduces multitasking thrash and improves flow.
- Add forced-strategy pivot after 3 same-task attempts (new test axis, narrower scope, or rollback-to-last-pass baseline).
- Add retry backoff with jitter for automation retries to avoid synchronized retry storms when tool/API noise appears.
- After max retries, auto-route task ID to dead-letter/triage queue with explicit blocker evidence instead of immediate reselection.
- Track loop health with delivery metrics (lead time/change failure/recovery) to detect no-progress cycles early.

References:
- https://www.atlassian.com/agile/kanban/wip-limits
- https://sre.google/sre-book/service-best-practices/
- https://cloud.google.com/blog/products/devops-sre/using-the-four-keys-to-measure-your-devops-performance
- https://aws.amazon.com/blogs/aws/amazon-sqs-new-dead-letter-queue/
