---
type: navigation
status: active
updated: 2026-10-29
tags:
  - navigation
---

# Architecture

> Every layer has one job. A rebuildable cache never becomes the source of truth.

| Layer | Role | Failure behavior |
|---|---|---|
| Markdown | Durable facts and links | Restore from Git if damaged |
| Obsidian | Human editing and views | Reopen the folder; settings may reset without data loss |
| Bases | Saved queries and dashboards | Recreate from Markdown metadata |
| Basic Memory | Search and semantic index | Rebuild from Markdown |
| Change scanner | Candidate discovery | Re-run; it does not modify notes |
| Agent | Low-risk structural maintenance | Stop on ambiguity or validation failure |
| Git | History and remote recovery | Restore a known commit |

## Maintenance transaction

```text
1. Check for staged changes and recent edits
2. Scan working-tree and committed Markdown changes
3. Let the agent inspect candidates and the manual queue
4. Run structural validation
5. Optionally reindex Basic Memory
6. Stage only approved files
7. Commit
8. Push
9. Advance the successful checkpoint
```

The checkpoint advances only after local validation succeeds. A failed push leaves a local commit that can be retried.

## Trust boundaries

- Original evidence is never normalized by the agent.
- Generated indexes are disposable.
- The maintenance queue represents work that should not be forgotten.
- `log.md` is append-only.
- Pre-staged user changes block automatic maintenance so unrelated work is not included in an automated commit.

## Related

- [[docs/system-design|Detailed system design]]
- [[docs/automation|Automation guide]]
- [[00_navigation/agent-maintenance|Maintenance protocol]]
