# Setup Guide

> Brainyard runs as a normal folder. Obsidian and AI tools are clients; Markdown remains the data.

## Requirements

| Requirement | Needed for |
|---|---|
| Obsidian | Recommended editor |
| Git | History and remote recovery |
| PowerShell 7 | Validation and automation scripts |
| GitHub CLI | Optional repository creation and authentication |
| Codex-compatible CLI | Optional scheduled AI maintenance |
| Basic Memory | Optional semantic search |

## Install

```powershell
git clone <repository-url> brainyard
Set-Location brainyard
Copy-Item brainyard.config.example.json brainyard.config.json
pwsh ./tools/wiki_check.ps1 -IncludeWarnings
```

Open the repository root as an Obsidian vault.

## Configure automation

`brainyard.config.json` is local and ignored by Git:

```json
{
  "basicMemoryProject": "brainyard",
  "maintenance": {
    "idleMinutes": 10,
    "startupDelaySeconds": 300
  },
  "agent": {
    "command": "codex",
    "sandbox": "workspace-write"
  }
}
```

If `basicMemoryProject` is blank, reindexing is skipped. If `agent.command` is not on `PATH`, provide an absolute path.

## Enable Windows scheduling

Review `tools/maintenance-prompt.txt` first.

```powershell
pwsh ./tools/install_windows_tasks.ps1
```

The installer registers:

- daily maintenance at 00:00;
- a login fallback after five minutes;
- battery-friendly execution;
- recovery after a missed trigger.

Remove the task:

```powershell
pwsh ./tools/install_windows_tasks.ps1 -Uninstall
```

## macOS and Linux

Validation and scanning scripts work with PowerShell 7. The Windows task installer does not. Use `cron` or `systemd` to execute:

```text
pwsh /path/to/brainyard/tools/run_maintenance.ps1
```

## Validate the installation

```powershell
pwsh ./tools/tests/test_scan_changes.ps1
pwsh ./tools/run_maintenance.ps1 -CheckOnly -IdleMinutes 0
```

## Related

- [[docs/automation|Automation guide]]
- [[SECURITY|Security policy]]
- [[00_navigation/start-here|Start here]]
