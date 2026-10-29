# Brainyard Agent Contract

> Read this file before any substantive change. Brainyard is a maintenance-first knowledge base, and file safety has priority over tidiness.

## Read order

1. `AGENTS.md`
2. `00_navigation/agent-classification.md`
3. `00_navigation/agent-maintenance.md`
4. `00_navigation/agent-delivery.md`
5. `00_navigation/maintenance-queue.md`
6. `00_navigation/rule-tests.md`

If a required file is missing, stop and repair the structure first.

## Conflict priority

1. Platform, legal, and security requirements.
2. The user's current explicit request.
3. Privacy and prevention of irreversible data loss.
4. Factual accuracy and source traceability.
5. Git recoverability and history integrity.
6. Classification and long-term maintainability.
7. Automation efficiency.
8. Visual polish.

## Core boundaries

- `01_materials/` is read-only evidence. Never rewrite, normalize, or silently delete its originals.
- Markdown is the source of truth. Bases, search indexes, embeddings, and caches are rebuildable views.
- One object has one primary path. Cross-category relationships use tags and internal links.
- Preserve ambiguous wording until the user clarifies its purpose.
- Before merging objects, distinguish alias, containment, overlap, dependency, and superficial name similarity.
- Do not invent facts, roles, achievements, credentials, sources, or capabilities.
- Do not silently delete, overwrite, or perform large structural moves.
- New automation rules require scenario tests and updates to affected documentation.

## Classification

- Parent and child categories cannot sit at the same level.
- A single child is stored as `parent/child.md`, not `child/child.md`.
- A parent page lists its direct children and every child links back to the parent.
- Versions, dates, and status are fields, not permanent categories.
- Uncertain ideas may go to a local `inbox/` page, but do not create a permanent category until evidence supports it.
- A move must update parent pages, `index.md`, `log.md`, and any affected links.

Ask before:

- changing a top-level folder;
- moving or merging multiple existing cards;
- choosing between two equally valid parents;
- changing frontmatter schema or supported tags.

## Maintenance

The automatic loop is:

```text
scan content changes
→ inspect candidate pages
→ apply low-risk structural fixes
→ validate
→ optionally reindex
→ commit approved files
→ push Git
→ advance the checkpoint
```

Low-risk automatic work:

- add missing internal links;
- repair a clear parent/child relationship;
- add tags when the relationship is explicit;
- update parent pages, `index.md`, and `log.md`;
- record unresolved work in `00_navigation/maintenance-queue.md`.

High-risk work requiring confirmation:

- deleting body text or source material;
- restoring a file the user deleted;
- resolving contradictory facts;
- merging disputed pages;
- changing top-level structure;
- inventing or completing personal evidence.

## Delivery report

Every substantive task must report:

- completed work;
- verified checks;
- unverified items;
- items requiring user confirmation;
- side effects such as writes, moves, deletions, or external pushes.

## Validation

Run:

```powershell
pwsh ./tools/wiki_check.ps1 -IncludeWarnings
```

For scanner changes, also run:

```powershell
pwsh ./tools/tests/test_scan_changes.ps1
```

Do not claim a rule or workflow is complete when its test fails.

## Related

- [[00_navigation/start-here|Start here]]
- [[00_navigation/knowledge-model|Knowledge model]]
- [[00_navigation/maintenance-queue|Maintenance queue]]
