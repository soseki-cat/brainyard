# System Design

> Brainyard is designed around reversible automation.

## Source-of-truth model

```text
Markdown
├── durable content
├── metadata
├── links
└── provenance

Derived layers
├── Obsidian views and Bases
├── Basic Memory text/vector index
└── maintenance candidate files
```

Derived layers may be deleted and rebuilt. Markdown is restored from Git if damaged.

## Components

| Component | Input | Output | Mutates notes |
|---|---|---|---|
| `wiki_check.ps1` | Markdown vault | pass/fail report | no |
| `scan_changes.ps1` | Git state and Markdown | `change-candidates.json` | no |
| `run_maintenance.ps1` | candidates, queue, agent | validation, commit, push | only through approved paths |
| `wiki_check.ps1` in CI | repository | GitHub Actions result | no |
| Basic Memory | Markdown | local search index | may add system metadata |

## Safety model

Before an automatic run:

1. Files modified within the idle window cause a skip.
2. A non-empty Git staging area causes a skip.
3. Raw material and control files are excluded from candidate discovery.

Before a commit:

1. The agent must not commit independently.
2. Structural validation must pass.
3. Optional reindexing must pass.
4. Only final scanned content and three control pages may be staged.

Before checkpoint advancement:

1. Local changes must be committed or absent.
2. The current `HEAD` is recorded in local runtime state.

## Failure behavior

| Failure | Result |
|---|---|
| User is editing | Skip |
| Files already staged | Skip |
| Scanner fails | No agent, no commit |
| Agent fails | No commit |
| Reindex fails | No commit |
| Post-check fails | No commit |
| Commit fails | No checkpoint advance |
| Push fails | Local commit remains; retry later |

## Extension points

- Add domain folders under `10_domains/`.
- Add software cards under `20_tools/`.
- Add source-capture conventions under `01_materials/`.
- Customize `tools/maintenance-prompt.txt` for the chosen agent.
- Keep `wiki_check.ps1` independent from any specific AI provider.

## Related

- [[docs/automation|Automation guide]]
- [[00_navigation/architecture|Architecture summary]]
