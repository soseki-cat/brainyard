---
type: navigation
status: active
updated: 2026-10-29
tags:
  - navigation
---

# Knowledge Model

> The folder tree represents the primary classification. Tags and links represent secondary relationships.

| Layer | Location | Responsibility | Automation boundary |
|---|---|---|---|
| Raw evidence | `01_materials/` | Original PDFs, images, transcripts, and clippings | Read-only |
| Knowledge | `10_domains/` | Durable subjects, concepts, projects, and decisions | Low-risk links and structure only |
| Tools | `20_tools/` | Software and workflow references | Low-risk links and structure only |
| Control | `00_navigation/`, `AGENTS.md`, `index.md`, `log.md` | Rules, entry points, queue, and history | Agent updates require care |
| Templates | `90_templates/` | Reusable card structures | Copy before editing |
| Runtime | `tools/`, `.github/` | Validation, automation, and CI | Code review required |

## Parent and child

Correct:

```text
topic/
├── topic.md
├── subtopic-a.md
└── subtopic-b.md
```

Avoid:

```text
topic/
subtopic-a/
subtopic-b/
```

The tree should describe `is-a`, `part-of`, or a stable domain boundary. Use links for “related to”, “uses”, “depends on”, or “similar to”.

## Frontmatter

Content pages use four author-maintained fields:

```yaml
---
type: concept
status: active
updated: 2026-10-29
tags:
  - example
---
```

Optional indexers may add a fifth system-managed field such as `permalink`. Do not hand-edit fields owned by an external indexer.

## Evidence quality

Classify claims as:

- **Confirmed**: directly supported by a source or reproducible test.
- **Likely**: supported but still missing a key verification.
- **Inference**: reasoned from available evidence.
- **Unknown**: not enough information.

## Related

- [[AGENTS]]
- [[00_navigation/agent-classification|Classification protocol]]
- [[90_templates/concept-card|Concept card template]]
