---
type: navigation
status: active
updated: 2026-10-29
tags:
  - navigation
---

# Start Here

> Brainyard works best when capture, classification, and maintenance remain separate.

## First run

1. Copy `brainyard.config.example.json` to `brainyard.config.json`.
2. Run `pwsh ./tools/wiki_check.ps1 -IncludeWarnings`.
3. Replace the example domain and tool pages with your own material.
4. Keep source evidence in `01_materials/`.
5. Start new cards from `90_templates/`.
6. Link every content card from a parent page and `index.md`.
7. Commit before enabling scheduled maintenance.

## Daily workflow

| Situation | Action |
|---|---|
| Save a PDF, image, transcript, or clipping | Put it in `01_materials/`; leave the original unchanged |
| Write a reusable conclusion | Create or update a card in `10_domains/` |
| Learn a software workflow | Create or update a card in `20_tools/` |
| Encounter an unclear idea | Preserve the wording in a safe inbox page |
| Make a structural change | Update the parent, index, log, and affected links |

## Before sharing or publishing

- Remove personal identifiers, credentials, private URLs, and confidential project data.
- Check image metadata and screenshots.
- Confirm that `01_materials/` is ignored or intentionally redacted.
- Prefer a private Git remote for a personal vault.

## Related

- [[AGENTS]]
- [[00_navigation/knowledge-model|Knowledge model]]
- [[docs/setup|Setup guide]]
