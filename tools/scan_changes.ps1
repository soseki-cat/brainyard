[CmdletBinding()]
param(
    [string]$VaultPath = (Split-Path -Parent $PSScriptRoot),
    [string]$OutputFile,
    [string]$StateFile,
    [switch]$Json,
    [switch]$AdvanceState
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$vault = (Resolve-Path -LiteralPath $VaultPath).Path
$maintenanceDir = Join-Path (Join-Path $vault 'tools') 'maintenance'
if ([string]::IsNullOrWhiteSpace($OutputFile)) {
    $OutputFile = Join-Path $maintenanceDir 'change-candidates.json'
}
if ([string]::IsNullOrWhiteSpace($StateFile)) {
    $StateFile = Join-Path $maintenanceDir 'scan-state.json'
}
New-Item -ItemType Directory -Path $maintenanceDir -Force | Out-Null

$gitCommand = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitCommand) {
    throw 'Git executable not found.'
}

function Invoke-GitLines {
    param([string[]]$GitArgs)

    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $output = & $gitCommand.Source -C $vault -c core.quotepath=false @GitArgs 2>&1
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorAction
    if ($exitCode -ne 0) {
        $detail = ($output | ForEach-Object { $_.ToString() }) -join "`n"
        throw "git $($GitArgs -join ' ') failed with exit code $exitCode`n$detail"
    }
    return @($output | ForEach-Object { $_.ToString() })
}

function Write-Utf8Text {
    param([string]$Path, [string]$Text)

    $encoding = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::WriteAllText($Path, $Text, $encoding)
}

function Test-CandidatePath {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    $normalized = $Path.Replace('\', '/')
    while ($normalized.StartsWith('./')) { $normalized = $normalized.Substring(2) }
    if (-not $normalized.ToLowerInvariant().EndsWith('.md')) { return $false }

    $reserved = @(
        'AGENTS.md', 'CLAUDE.md', 'README.md', 'CONTRIBUTING.md',
        'SECURITY.md', 'CODE_OF_CONDUCT.md', 'CHANGELOG.md', 'index.md', 'log.md'
    )
    if ($normalized -in $reserved) { return $false }

    $excludedPrefixes = @(
        '.git/', '.obsidian/', '.claudian/', '.github/', '00_navigation/',
        '01_materials/', '90_templates/', 'docs/', 'tools/'
    )
    foreach ($prefix in $excludedPrefixes) {
        if ($normalized.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
            return $false
        }
    }
    return $true
}

$headCommit = $null
$previousErrorAction = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$headOutput = & $gitCommand.Source -C $vault rev-parse --verify HEAD 2>$null
$headExit = $LASTEXITCODE
$ErrorActionPreference = $previousErrorAction
if ($headExit -eq 0) {
    $headCommit = ($headOutput | Select-Object -First 1).ToString().Trim()
}

if ($AdvanceState) {
    if ([string]::IsNullOrWhiteSpace($headCommit)) {
        throw 'Cannot advance the scan checkpoint before the repository has a commit.'
    }
    $advanced = [ordered]@{
        lastProcessedHead = $headCommit
        updatedAt = (Get-Date).ToString('o')
    }
    Write-Utf8Text -Path $StateFile -Text ($advanced | ConvertTo-Json)
    Write-Output "Scan state advanced to $headCommit."
    exit 0
}

$baselineCommit = $null
$historyAvailable = $false
$historyNote = 'No previous scan state; committed history was not replayed.'
if (Test-Path -LiteralPath $StateFile) {
    try {
        $savedState = Get-Content -Raw -LiteralPath $StateFile | ConvertFrom-Json
        if ($null -ne $savedState.lastProcessedHead -and -not [string]::IsNullOrWhiteSpace($savedState.lastProcessedHead)) {
            $baselineCommit = [string]$savedState.lastProcessedHead
        }
    }
    catch {
        $historyNote = "Scan state could not be read: $($_.Exception.Message)"
    }
}

if (-not [string]::IsNullOrWhiteSpace($baselineCommit)) {
    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & $gitCommand.Source -C $vault cat-file -e "$baselineCommit^{commit}" 2>$null
    $baselineExists = $LASTEXITCODE -eq 0
    $ErrorActionPreference = $previousErrorAction

    if ($baselineExists) {
        if ($baselineCommit -eq $headCommit) {
            $historyAvailable = $true
            $historyNote = 'No commits after the last processed checkpoint.'
        }
        else {
            $previousErrorAction = $ErrorActionPreference
            $ErrorActionPreference = 'Continue'
            & $gitCommand.Source -C $vault merge-base --is-ancestor $baselineCommit $headCommit 2>$null
            $isAncestor = $LASTEXITCODE -eq 0
            $ErrorActionPreference = $previousErrorAction
            if ($isAncestor) {
                $historyAvailable = $true
                $historyNote = "Comparing commits $baselineCommit..$headCommit."
            }
            else {
                $historyNote = 'The saved checkpoint is not an ancestor of HEAD.'
            }
        }
    }
}

$changesByPath = @{}

function Add-Change {
    param(
        [string]$Kind,
        [string]$Path,
        [string]$Source,
        [string]$PreviousPath = ''
    )

    $normalizedPath = $Path.Replace('\', '/')
    if (-not (Test-CandidatePath -Path $normalizedPath)) { return }
    $changesByPath[$normalizedPath] = [ordered]@{
        kind = $Kind
        path = $normalizedPath
        previousPath = $PreviousPath.Replace('\', '/')
        source = $Source
    }
}

function Add-NameStatusLines {
    param([string[]]$Lines, [string]$Source)

    foreach ($line in $Lines) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $parts = $line -split "`t"
        if ($parts.Count -lt 2) { continue }
        $code = $parts[0]
        if ($code.StartsWith('R') -or $code.StartsWith('C')) {
            if ($parts.Count -ge 3) {
                $kind = if ($code.StartsWith('R')) { 'renamed' } else { 'added' }
                Add-Change -Kind $kind -Path $parts[2] -PreviousPath $parts[1] -Source $Source
            }
            continue
        }
        $kind = switch -Regex ($code) {
            '^D' { 'deleted'; break }
            '^A' { 'added'; break }
            default { 'modified' }
        }
        Add-Change -Kind $kind -Path $parts[1] -Source $Source
    }
}

if ($historyAvailable -and $baselineCommit -ne $headCommit) {
    $historyLines = Invoke-GitLines -GitArgs @('diff', '--name-status', '-M', "$baselineCommit..$headCommit", '--', '*.md')
    Add-NameStatusLines -Lines $historyLines -Source 'committed'
}

if (-not [string]::IsNullOrWhiteSpace($headCommit)) {
    $workingLines = Invoke-GitLines -GitArgs @('diff', '--name-status', '-M', 'HEAD', '--', '*.md')
    Add-NameStatusLines -Lines $workingLines -Source 'working-tree'
}

$untrackedLines = Invoke-GitLines -GitArgs @('ls-files', '--others', '--exclude-standard', '--', '*.md')
foreach ($path in $untrackedLines) {
    Add-Change -Kind 'added' -Path $path -Source 'working-tree'
}

$changes = @($changesByPath.Values | Sort-Object -Property path)
$summary = [ordered]@{
    total = $changes.Count
    added = @($changes | Where-Object { $_.kind -eq 'added' }).Count
    modified = @($changes | Where-Object { $_.kind -eq 'modified' }).Count
    deleted = @($changes | Where-Object { $_.kind -eq 'deleted' }).Count
    renamed = @($changes | Where-Object { $_.kind -eq 'renamed' }).Count
}

$result = [ordered]@{
    generatedAt = (Get-Date).ToString('o')
    headCommit = $headCommit
    baselineCommit = $baselineCommit
    historyAvailable = $historyAvailable
    historyNote = $historyNote
    summary = $summary
    changes = $changes
}
$jsonText = $result | ConvertTo-Json -Depth 8
Write-Utf8Text -Path $OutputFile -Text $jsonText

if ($Json) {
    Write-Output $jsonText
}
else {
    [pscustomobject]@{
        HeadCommit = $headCommit
        BaselineCommit = $baselineCommit
        HistoryAvailable = $historyAvailable
        Changes = $summary.total
        Added = $summary.added
        Modified = $summary.modified
        Deleted = $summary.deleted
        Renamed = $summary.renamed
        OutputFile = $OutputFile
    } | Format-List
}
