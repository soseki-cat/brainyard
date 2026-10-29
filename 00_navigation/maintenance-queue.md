---
type: navigation
status: active
updated: 2026-10-29
tags:
  - navigation
---

# Maintenance Queue

> Record deferred, ambiguous, or high-risk work here. The user should not have to remember it.

## Trigger rules

| Condition | Action |
|---|---|
| The user is still editing | Do not interrupt; record work if needed |
| More than 10 minutes have passed since the last edit | Low-risk maintenance may run |
| The computer was off | Run at the next login or scheduled recovery |
| The requested action deletes, merges, or restructures | Mark `needs-confirmation` |

## Open items

| ID | Date | Source | Next action | Risk | Status |
|---|---|---|---|---|---|
| EXAMPLE-001 | 2026-10-29 | Demonstration row | Replace this row with real maintenance work | low | open |

## Completion record

| Date | ID | Work completed | Evidence |
|---|---|---|---|
| 2026-10-29 | BOOT-001 | Framework skeleton and validation workflow created | `tools/wiki_check.ps1` |

## Allowed status values

- `open`
- `deferred`
- `needs-confirmation`
- `completed`

## Related

- [[AGENTS]]
- [[00_navigation/rule-tests|Rule tests]]
- [[log|Maintenance log]]
