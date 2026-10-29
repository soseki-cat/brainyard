---
type: process
status: active
updated: 2026-10-29
tags:
  - navigation
---

# Agent Classification Protocol

> Classification comes before moving or creating cards.

## Decision order

1. Search for an existing parent.
2. Determine the relationship:
   - subtype: parent/child;
   - component: parent/child;
   - dependency or sequence: keep peers and link them;
   - status, date, or version: use a field;
   - loose reference: use a tag or link.
3. Choose exactly one primary path.
4. Avoid a wrapper folder for a single child.
5. Update the parent, child backlink, index, and log.

## Merge matrix

| Relationship | Action |
|---|---|
| Alias or duplicate | Merge and preserve aliases and sources |
| One fully contains another | Convert to parent/child |
| Partial overlap | Keep primary paths separate and link them |
| Dependency or sequence | Keep peers and state the relation |
| Similar names only | Inspect definitions before merging |
| Unrelated | Do not force a shared category |

## Ambiguous input

Preserve the original wording, identify the intended use, and offer 2–3 concrete destination scenarios. Ask one focused question when the answer changes the structure materially.

## Related

- [[AGENTS]]
- [[00_navigation/knowledge-model|Knowledge model]]
- [[00_navigation/rule-tests|Rule tests]]
