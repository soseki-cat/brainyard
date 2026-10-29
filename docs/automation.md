# Automation Guide

> The scanner discovers work. The agent proposes low-risk changes. The wrapper decides whether anything may be committed.

## Manual checks

```powershell
pwsh ./tools/scan_changes.ps1 -Json
pwsh ./tools/wiki_check.ps1 -IncludeWarnings
pwsh ./tools/run_maintenance.ps1 -CheckOnly -IdleMinutes 0
```

## Full run

```powershell
pwsh ./tools/run_maintenance.ps1
```

Force a run while developing:

```powershell
pwsh ./tools/run_maintenance.ps1 -Force
```

## State files

Runtime files are ignored by Git:

```text
tools/maintenance/
├── change-candidates.json
├── change-candidates-final.json
├── scan-state.json
├── state.json
└── *.log
```

## Candidate rules

Included:

- `10_domains/**/*.md`
- `20_tools/**/*.md`
- other Markdown outside excluded control and raw directories

Excluded:

- `01_materials/`
- `00_navigation/`
- `90_templates/`
- `tools/`
- `.obsidian/`
- `AGENTS.md`, `CLAUDE.md`, `index.md`, and `log.md`

## Committed paths

The wrapper stages:

1. final scanner-approved content paths;
2. `index.md`;
3. `log.md`;
4. `00_navigation/maintenance-queue.md`.

Other files remain untouched even if the agent creates them accidentally. They must be reviewed manually.

## Custom agent

The default runner uses:

```text
<agent.command> exec -C <vault> -s <sandbox> -
```

Update `tools/run_maintenance.ps1` if your agent has a different CLI contract.

## GitHub Actions

`.github/workflows/validate.yml` runs the scanner test and vault validation on Windows. It does not run AI maintenance and does not need secrets.

## Related

- [[docs/setup|Setup guide]]
- [[00_navigation/agent-maintenance|Agent maintenance protocol]]
