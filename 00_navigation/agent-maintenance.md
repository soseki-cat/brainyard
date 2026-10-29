---
type: process
status: active
updated: 2026-10-29
tags:
  - navigation
---

# Agent Maintenance Protocol

> Original evidence is immutable. Maintenance is delayed until the user is idle.

## Capture

1. Save the source first.
2. Record provenance, version, date, and limits.
3. Put durable conclusions in domain cards.
4. Keep one-off chat answers in the conversation unless they are reusable.
5. Delete nothing from `01_materials/` automatically.

## Change discovery

`tools/scan_changes.ps1`:

- checks uncommitted Markdown changes;
- compares the last successful checkpoint with `HEAD`;
- writes `tools/maintenance/change-candidates.json`;
- excludes raw material, navigation, templates, tools, and editor state.

The scanner does not modify notes.

## Automatic work

Allowed:

- add missing links;
- update tags when the relationship is explicit;
- update parent pages;
- update `index.md` and append to `log.md`;
- record unresolved work in the maintenance queue.

Not allowed without confirmation:

- delete source or body content;
- merge disputed cards;
- change top-level structure;
- modify frontmatter schema;
- invent personal facts or evidence.

## Commit policy

`tools/run_maintenance.ps1` stages only:

- scanner-approved content changes;
- `index.md`;
- `log.md`;
- `00_navigation/maintenance-queue.md`.

Validation or reindex failure blocks commit and checkpoint advancement.

## Related

- [[docs/automation|Automation guide]]
- [[00_navigation/maintenance-queue|Maintenance queue]]
- [[SECURITY]]
