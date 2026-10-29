[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$CheckOnly,
    [int]$IdleMinutes = -1
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$vault = Split-Path -Parent $PSScriptRoot
$logDir = Join-Path $PSScriptRoot 'maintenance'
$stateFile = Join-Path $logDir 'state.json'
$configFile = Join-Path $vault 'brainyard.config.json'
New-Item -ItemType Directory -Path $logDir -Force | Out-Null

$config = [ordered]@{
    basicMemoryProject = ''
    maintenance = [ordered]@{ idleMinutes = 10 }
    agent = [ordered]@{ command = 'codex'; sandbox = 'workspace-write' }
}
if (Test-Path -LiteralPath $configFile) {
    $loaded = Get-Content -Raw -LiteralPath $configFile | ConvertFrom-Json
    $basicMemoryProperty = $loaded.PSObject.Properties['basicMemoryProject']
    if ($null -ne $basicMemoryProperty -and $null -ne $basicMemoryProperty.Value) {
        $config.basicMemoryProject = [string]$basicMemoryProperty.Value
    }
    $maintenanceProperty = $loaded.PSObject.Properties['maintenance']
    if ($null -ne $maintenanceProperty -and $null -ne $maintenanceProperty.Value) {
        $idleProperty = $maintenanceProperty.Value.PSObject.Properties['idleMinutes']
        if ($null -ne $idleProperty -and $null -ne $idleProperty.Value) {
            $config.maintenance.idleMinutes = [int]$idleProperty.Value
        }
    }
    $agentProperty = $loaded.PSObject.Properties['agent']
    if ($null -ne $agentProperty -and $null -ne $agentProperty.Value) {
        $commandProperty = $agentProperty.Value.PSObject.Properties['command']
        if ($null -ne $commandProperty -and $null -ne $commandProperty.Value) {
            $config.agent.command = [string]$commandProperty.Value
        }
        $sandboxProperty = $agentProperty.Value.PSObject.Properties['sandbox']
        if ($null -ne $sandboxProperty -and $null -ne $sandboxProperty.Value) {
            $config.agent.sandbox = [string]$sandboxProperty.Value
        }
    }
}
if ($IdleMinutes -lt 0) {
    $IdleMinutes = [int]$config.maintenance.idleMinutes
}

$pwshCommand = Get-Command pwsh -ErrorAction SilentlyContinue
$shellPath = if ($pwshCommand) {
    $pwshCommand.Source
}
else {
    (Get-Process -Id $PID).Path
}

$sha256 = [Security.Cryptography.SHA256]::Create()
$vaultHashBytes = $sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes($vault.ToLowerInvariant()))
$vaultHash = [BitConverter]::ToString($vaultHashBytes).Replace('-', '').Substring(0, 12)
$sha256.Dispose()
$mutexName = "Local\BrainyardMaintenance-$vaultHash"
$mutex = New-Object System.Threading.Mutex($false, $mutexName)
if (-not $mutex.WaitOne(0)) {
    Write-Output 'Another Brainyard maintenance run is active; skipped.'
    exit 0
}

try {
    $now = Get-Date
    $logFile = Join-Path $logDir ('{0:yyyyMMdd-HHmmss}.log' -f $now)
    $contentFiles = @(
        Get-ChildItem -LiteralPath $vault -Recurse -File -Force |
            Where-Object {
                $_.FullName -notmatch '\\(\.git|\.obsidian|\.claudian|tools\\maintenance)\\'
            }
    )
    $recent = @($contentFiles | Where-Object { $_.LastWriteTime -gt $now.AddMinutes(-$IdleMinutes) })
    if ($recent.Count -gt 0 -and -not $Force) {
        $message = 'Skipped: files changed within the last {0} minutes.' -f $IdleMinutes
        $message | Set-Content -LiteralPath $logFile -Encoding utf8
        Write-Output $message
        exit 0
    }

    $gitCommand = Get-Command git -ErrorAction SilentlyContinue
    if (-not $gitCommand) {
        throw 'Git executable not found.'
    }

    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & $gitCommand.Source -C $vault diff --cached --quiet
    $hasPrestagedChanges = $LASTEXITCODE -ne 0
    $ErrorActionPreference = $previousErrorAction
    if ($hasPrestagedChanges) {
        $message = 'Skipped: Git index already contains staged changes.'
        $message | Set-Content -LiteralPath $logFile -Encoding utf8
        Write-Output $message
        exit 0
    }

    $scanner = Join-Path $PSScriptRoot 'scan_changes.ps1'
    $scanFile = Join-Path $logDir 'change-candidates.json'
    $scanOutput = & $shellPath -NoProfile -File $scanner -VaultPath $vault -OutputFile $scanFile 2>&1 | Out-String
    $scanExit = $LASTEXITCODE
    $scanOutput | Set-Content -LiteralPath $logFile -Encoding utf8
    if ($scanExit -ne 0) {
        Write-Output "Change scan failed with exit code $scanExit. See $logFile"
        exit $scanExit
    }
    $scanData = Get-Content -Raw -LiteralPath $scanFile | ConvertFrom-Json
    $changeCount = [int]$scanData.summary.total

    $checker = Join-Path $PSScriptRoot 'wiki_check.ps1'
    $precheck = & $shellPath -NoProfile -File $checker 2>&1 | Out-String
    $precheckExit = $LASTEXITCODE
    Add-Content -LiteralPath $logFile -Value "`n===== PRE CHECK =====`n$precheck" -Encoding utf8
    if ($precheckExit -ne 0 -and $changeCount -eq 0) {
        Write-Output 'Pre-check failed and no Markdown candidates were found; agent was not started.'
        exit 1
    }

    if ($CheckOnly) {
        if ($precheckExit -ne 0) {
            Write-Output 'Pre-check failed during a check-only run.'
            exit 1
        }
        Write-Output 'Check-only run passed.'
        exit 0
    }

    $prompt = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'maintenance-prompt.txt') -Raw
    $precheckState = if ($precheckExit -eq 0) { 'passed' } else { 'failed' }
    $prompt += @"

## This run

- Candidate file: $scanFile
- Candidate count: $changeCount
- Initial structural check: $precheckState

If the candidate count is greater than zero, inspect every candidate before handling the manual queue.
Deletion and rename candidates are only for checking affected links; do not restore user-deleted files.
Do not create a Git commit. The wrapper validates, reindexes, stages approved files, commits, and pushes.
"@

    $configuredAgent = [string]$config.agent.command
    $agent = Get-Command $configuredAgent -ErrorAction SilentlyContinue
    if ($agent) {
        $agentPath = $agent.Source
    }
    elseif (Test-Path -LiteralPath $configuredAgent) {
        $agentPath = (Resolve-Path -LiteralPath $configuredAgent).Path
    }
    else {
        throw "Agent executable not found: $configuredAgent"
    }

    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $agentOutput = $prompt | & $agentPath exec `
        -C $vault `
        -s ([string]$config.agent.sandbox) `
        --color never `
        - 2>&1 | Out-String
    $agentExit = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorAction
    Add-Content -LiteralPath $logFile -Value "`n===== AGENT OUTPUT =====`n$agentOutput" -Encoding utf8
    if ($agentExit -ne 0) {
        Write-Output "Agent failed with exit code $agentExit. See $logFile"
        exit $agentExit
    }

    $reindexExit = 0
    $reindexSkipped = $true
    $basicMemoryProject = [string]$config.basicMemoryProject
    if (-not [string]::IsNullOrWhiteSpace($basicMemoryProject)) {
        $reindexSkipped = $false
        $basicMemory = Get-Command basic-memory -ErrorAction SilentlyContinue
        if (-not $basicMemory) {
            $fallback = Join-Path $env:USERPROFILE '.local\bin\basic-memory.exe'
            if (Test-Path -LiteralPath $fallback) {
                $basicMemoryPath = $fallback
            }
            else {
                throw 'Basic Memory is configured but no executable was found.'
            }
        }
        else {
            $basicMemoryPath = $basicMemory.Source
        }
        $reindex = & $basicMemoryPath reindex --project $basicMemoryProject 2>&1 | Out-String
        $reindexExit = $LASTEXITCODE
        Add-Content -LiteralPath $logFile -Value "`n===== BASIC MEMORY REINDEX =====`n$reindex" -Encoding utf8
        if ($reindexExit -ne 0) {
            Write-Output "Basic Memory reindex failed with exit code $reindexExit. No commit was created."
            exit $reindexExit
        }
    }

    $postcheck = & $shellPath -NoProfile -File $checker 2>&1 | Out-String
    $postcheckExit = $LASTEXITCODE
    Add-Content -LiteralPath $logFile -Value "`n===== POST CHECK =====`n$postcheck" -Encoding utf8
    if ($postcheckExit -ne 0) {
        Write-Output "Post-check failed with exit code $postcheckExit. No commit was created. See $logFile"
        exit $postcheckExit
    }

    $finalScanFile = Join-Path $logDir 'change-candidates-final.json'
    $finalScanOutput = & $shellPath -NoProfile -File $scanner -VaultPath $vault -OutputFile $finalScanFile 2>&1 | Out-String
    $finalScanExit = $LASTEXITCODE
    Add-Content -LiteralPath $logFile -Value "`n===== FINAL CHANGE SCAN =====`n$finalScanOutput" -Encoding utf8
    if ($finalScanExit -ne 0) {
        throw "Final change scan failed with exit code $finalScanExit"
    }
    $finalScanData = Get-Content -Raw -LiteralPath $finalScanFile | ConvertFrom-Json
    $stagePaths = @(
        foreach ($change in $finalScanData.changes) {
            $change.path
            if (-not [string]::IsNullOrWhiteSpace($change.previousPath)) {
                $change.previousPath
            }
        }
    )
    foreach ($controlPath in @('index.md', 'log.md', '00_navigation\maintenance-queue.md')) {
        if (Test-Path -LiteralPath (Join-Path $vault $controlPath)) {
            $stagePaths += $controlPath
        }
    }
    $stagePaths = @($stagePaths | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)

    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $addOutput = ''
    $addExit = 0
    if ($stagePaths.Count -gt 0) {
        $addOutput = & $gitCommand.Source -C $vault add -A -- $stagePaths 2>&1 | Out-String
        $addExit = $LASTEXITCODE
    }
    if ($addExit -ne 0) {
        $ErrorActionPreference = $previousErrorAction
        throw "Git add failed with exit code $addExit`n$addOutput"
    }

    & $gitCommand.Source -C $vault diff --cached --quiet
    $hasStagedChanges = $LASTEXITCODE -ne 0
    $commitCreated = $false
    $commitOutput = ''
    if ($hasStagedChanges) {
        $commitMessage = 'automatic maintenance: {0:yyyy-MM-dd}' -f $now
        $commitOutput = & $gitCommand.Source -C $vault commit -m $commitMessage 2>&1 | Out-String
        $commitExit = $LASTEXITCODE
        if ($commitExit -ne 0) {
            $ErrorActionPreference = $previousErrorAction
            throw "Git commit failed with exit code $commitExit`n$commitOutput"
        }
        $commitCreated = $true
    }
    $ErrorActionPreference = $previousErrorAction
    Add-Content -LiteralPath $logFile -Value "`n===== GIT COMMIT =====`n$commitOutput" -Encoding utf8

    $advanceOutput = & $shellPath -NoProfile -File $scanner -VaultPath $vault -StateFile (Join-Path $logDir 'scan-state.json') -AdvanceState 2>&1 | Out-String
    $advanceExit = $LASTEXITCODE
    Add-Content -LiteralPath $logFile -Value "`n===== SCAN STATE =====`n$advanceOutput" -Encoding utf8
    if ($advanceExit -ne 0) {
        throw "Scan state could not be advanced with exit code $advanceExit"
    }

    $pushSkipped = $false
    $pushExit = 0
    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & $gitCommand.Source -C $vault remote get-url origin 2>$null | Out-Null
    $hasOrigin = $LASTEXITCODE -eq 0
    if (-not $hasOrigin) {
        $pushSkipped = $true
    }
    else {
        $pushOutput = ''
        $pushExit = 1
        foreach ($attempt in 1..3) {
            $pushOutput += & $gitCommand.Source -C $vault push 2>&1 | Out-String
            $pushExit = $LASTEXITCODE
            if ($pushExit -eq 0) { break }
            Start-Sleep -Seconds 2
        }
        Add-Content -LiteralPath $logFile -Value "`n===== GIT PUSH =====`n$pushOutput" -Encoding utf8
    }
    $ErrorActionPreference = $previousErrorAction

    $status = [ordered]@{
        lastRun = $now.ToString('o')
        lastLog = $logFile
        precheckPassed = ($precheckExit -eq 0)
        precheckRecovered = (($precheckExit -ne 0) -and ($postcheckExit -eq 0))
        postcheckPassed = ($postcheckExit -eq 0)
        reindexSkipped = $reindexSkipped
        reindexPassed = ($reindexSkipped -or $reindexExit -eq 0)
        pushSkipped = $pushSkipped
        pushPassed = ($pushSkipped -or $pushExit -eq 0)
        scannedChanges = $changeCount
        commitCreated = $commitCreated
    }
    $status | ConvertTo-Json | Set-Content -LiteralPath $stateFile -Encoding utf8

    if ($postcheckExit -ne 0 -or $reindexExit -ne 0 -or $pushExit -ne 0) { exit 1 }
}
finally {
    $mutex.ReleaseMutex()
    $mutex.Dispose()
}
