# Brainyard

> A dry dock for ideas: a Markdown-first knowledge base that humans can edit and AI agents can maintain.

Brainyard is a reusable Obsidian vault framework for people who want an AI-assisted second brain without giving up file ownership, auditability, or the ability to leave the tool.

It treats Markdown as the source of truth, Git as the recovery layer, and AI indexing as a rebuildable cache. Optional helper scripts discover changes, run structural checks, create Git checkpoints, and leave disputed decisions in a maintenance queue.

## Why "Brainyard"

A shipyard is where vessels are assembled, inspected, repaired, and sent back into service. Brainyard applies the same idea to notes and project knowledge: capture evidence, assemble useful cards, inspect links, and schedule maintenance.

## What it does

- Provides a domain-neutral Obsidian folder model.
- Separates read-only source material from editable knowledge pages.
- Gives AI agents explicit classification, merge, privacy, and stop rules.
- Detects Markdown changes in the working tree and in commits since the last successful checkpoint.
- Validates frontmatter, headings, internal links, orphan pages, empty files, and duplicate basenames.
- Optionally reindexes Basic Memory as a search cache.
- Commits only approved Markdown and control pages after validation passes.
- Pushes a Git checkpoint and advances the maintenance state.
- Includes a Windows Task Scheduler installer and a GitHub Actions validation workflow.

## What it is not

- Not a cloud-drive replacement.
- Not a note generator that invents facts about you.
- Not a system that silently deletes, merges, or moves contested knowledge.
- Not tied to Basic Memory. The core vault and checker work without it.
- Not affiliated with Obsidian or Basic Memory.

## Best fit

Brainyard works well when:

- you keep long-lived notes in Markdown;
- you use Obsidian or another editor that can open a normal folder;
- you want Git history and an optional remote backup;
- you work with AI agents on a desktop;
- you want automation to stop before risky deletions or structural migrations.

It is probably overkill for a small recipe collection or a single short-lived project. It also expects some comfort with PowerShell, Git, and command-line tools.

## Architecture

```text
Brainyard/
├── AGENTS.md                  Agent operating contract
├── index.md                   Full knowledge index
├── log.md                     Append-only maintenance history
├── brainyard.config.json      Local settings, ignored by Git
├── 00_navigation/             Human and agent control pages
├── 01_materials/              Read-only source evidence
├── 10_domains/                Long-lived subject and project knowledge
├── 20_tools/                  Tool and software reference cards
├── 90_templates/              Reusable Markdown templates
├── docs/                      Setup, architecture and reference notes
├── tools/                     Validation and maintenance scripts
└── .github/                   CI, issue forms and contribution templates
```

The main data flow is:

```text
source material
→ editable knowledge cards
→ navigation and links
→ validation
→ Git checkpoint
→ optional semantic index
```

## Quick start

### 1. Create your copy

Use this repository as a GitHub template, or clone it manually:

```powershell
git clone <your-new-repository-url> my-brainyard
Set-Location my-brainyard
```

Open the folder as an Obsidian vault.

### 2. Copy the local configuration

```powershell
Copy-Item brainyard.config.example.json brainyard.config.json
```

`brainyard.config.json` is ignored by Git. Leave `basicMemoryProject` empty when you do not use Basic Memory.

### 3. Run the structural checker

```powershell
pwsh ./tools/wiki_check.ps1 -IncludeWarnings
```

Expected result: zero issues and zero warnings.

### 4. Start editing

1. Put original PDFs, screenshots, transcripts, and clippings in `01_materials/`.
2. Create durable knowledge under `10_domains/`.
3. Put software and tool notes under `20_tools/`.
4. Start new pages from `90_templates/`.
5. Keep every new card linked from a parent page and `index.md`.

### 5. Set up Git

```powershell
git add .
git commit -m "Initialize my Brainyard"
git remote add origin <your-private-or-public-repository-url>
git push -u origin main
```

A private repository is recommended when the knowledge base contains personal research, drafts, or internal project data.

### 6. Optional: Basic Memory

Brainyard can use [Basic Memory](https://github.com/basicmachines-co/basic-memory) as a semantic search cache. Markdown remains the source of truth.

1. Install Basic Memory.
2. Register this vault as a Basic Memory project.
3. Set `basicMemoryProject` in `brainyard.config.json`.
4. Run `basic-memory reindex --project <project-name>` once.

If `basicMemoryProject` is empty, the maintenance wrapper skips reindexing.

### 7. Optional: scheduled AI maintenance

The full agent runner currently targets a Codex-style CLI that supports:

```text
codex exec -C <vault> -s workspace-write -
```

Review `tools/maintenance-prompt.txt` before enabling it. Then install the Windows tasks:

```powershell
pwsh ./tools/install_windows_tasks.ps1
```

This creates:

- a daily maintenance task at 00:00;
- a startup fallback that runs five minutes after login;
- battery-friendly and missed-trigger recovery settings.

Run a safe check without invoking an agent:

```powershell
pwsh ./tools/run_maintenance.ps1 -CheckOnly -IdleMinutes 0
```

## Maintenance model

The automation has two separate jobs:

1. `scan_changes.ps1` discovers content changes and writes a machine-readable candidate list.
2. `run_maintenance.ps1` invokes the agent, validates the result, optionally reindexes, commits approved files, pushes Git, and advances the checkpoint.

Approved automatic changes include:

- adding missing internal links;
- updating parent pages and navigation;
- correcting tags or classification when the relation is unambiguous;
- updating `index.md` and appending to `log.md`;
- creating a checkpoint after successful validation.

Changes that remain manual:

- deleting source material or body text;
- resolving contradictory sources;
- merging disputed pages;
- changing top-level folders;
- inventing personal facts, credentials, or achievements;
- moving or rewriting `01_materials/`.

See [docs/system-design.md](docs/system-design.md), [docs/setup.md](docs/setup.md), and [docs/automation.md](docs/automation.md).

## Privacy and safety

- `.obsidian/workspace.json`, caches, sessions, and local configuration are ignored.
- `01_materials/` is treated as read-only evidence.
- The scanner excludes raw material, navigation, templates, tools, and editor state.
- The maintenance commit stages only scanned content and the three approved control pages.
- Pre-staged changes cause the automatic run to stop.
- Validation failure blocks commit and checkpoint advancement.

Read [SECURITY.md](SECURITY.md) before committing private records.

## Design references

Brainyard is an independent framework. It borrows concepts, not third-party application code, from:

- [Obsidian documentation](https://docs.obsidian.md/Home): local Markdown vaults and editable views.
- [Basic Memory](https://github.com/basicmachines-co/basic-memory): an optional Markdown-backed semantic knowledge index.
- [PARA](https://fortelabs.com/blog/para/): action-oriented separation between areas, projects, resources, and archives; Brainyard adapts the idea into source, domain, tool, and template layers.
- [AGENTS.md](https://agents.md/): repository-local operating instructions for coding agents.
- [GitHub community profile guidance](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/about-community-profiles-for-public-repositories): README, license, contribution, security, and issue-template files.
- [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and [Semantic Versioning](https://semver.org/): release documentation.
- [MIT License](https://choosealicense.com/licenses/mit/): permissive reuse.

Detailed attribution and scope are in [docs/references.md](docs/references.md).

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md) and run:

```powershell
pwsh ./tools/tests/test_scan_changes.ps1
pwsh ./tools/wiki_check.ps1 -IncludeWarnings
```

## License

MIT. See [LICENSE](LICENSE).
