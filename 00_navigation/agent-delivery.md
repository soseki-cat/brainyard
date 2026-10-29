---
type: process
status: active
updated: 2026-10-29
tags:
  - navigation
---

# Agent Delivery Protocol

> Reader-facing content should lead with the conclusion, then evidence, method, limits, and next step.

## Content page requirements

- Conclusion or purpose first.
- Facts before stylistic polish.
- Explicit evidence and limits.
- One H1 heading.
- A parent link and at least one related link.
- Frontmatter uses `type`, `status`, `updated`, and `tags`.

## Completion report

| Field | Meaning |
|---|---|
| Completed | Files or behavior actually changed |
| Verified | Commands and outcomes actually observed |
| Unverified | Items not tested or only inferred |
| Needs confirmation | Choices that require the user |
| Side effects | Writes, moves, deletions, pushes, or external calls |

## Hard stops

- Missing required protocol file.
- Failed validator after the agent has attempted a repair.
- Pre-staged changes before an automatic run.
- Request to delete or merge disputed material without confirmation.
- Unclear personal facts that would need invention.

## Related

- [[AGENTS]]
- [[00_navigation/rule-tests|Rule tests]]
- [[docs/system-design|System design]]
