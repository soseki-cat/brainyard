---
type: process
status: active
updated: 2026-10-29
tags:
  - navigation
---

# Rule Tests

> Every new behavioral rule needs a positive case, a negative case, and a boundary case.

| ID | Scenario | Expected behavior | Result |
|---|---|---|---|
| R-01 | “Fruit contains banana and apple” | Store banana and apple under fruit, not beside it | pass |
| R-02 | User writes an unclear phrase | Preserve the wording and ask a purpose-based question | pass |
| R-03 | Two names describe the same object | Merge only after aliases and sources are checked | pass |
| R-04 | One object partially overlaps another | Keep separate paths and connect with links | pass |
| R-05 | User edits a card without adding links | Detect the change and queue low-risk linking work | pass |
| R-06 | Structural validation fails | Do not commit or advance the checkpoint | pass |
| R-07 | User deletes raw evidence | Report the missing source; do not recreate or rewrite it | pass |
| R-08 | Required agent protocol is missing | Stop and repair the control layer first | pass |

## Change test checklist

1. State the behavior the rule changes.
2. Compare it with existing rules and merge duplicates.
3. Add positive, negative, and boundary scenarios.
4. Verify every path and command referenced by the rule.
5. Update affected templates and navigation.
6. Run `pwsh ./tools/wiki_check.ps1 -IncludeWarnings`.
7. Record the result here.

## Related

- [[AGENTS]]
- [[00_navigation/maintenance-queue|Maintenance queue]]
