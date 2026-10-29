[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$scanner = Join-Path $repoRoot 'tools\scan_changes.ps1'
$gitCommand = (Get-Command git -ErrorAction Stop).Source
$shellPath = (Get-Process -Id $PID).Path
$tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$fixture = Join-Path $tempRoot ('brainyard-scan-test-' + [guid]::NewGuid().ToString('N'))
$stateFile = Join-Path $fixture 'tools\maintenance\scan-state.json'
$outputFile = Join-Path $fixture 'tools\maintenance\change-candidates.json'

function Invoke-FixtureGit {
    param([string[]]$GitArgs)

    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $output = & $gitCommand -C $fixture @GitArgs 2>&1
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorAction
    if ($exitCode -ne 0) {
        throw "Fixture git command failed: git $($GitArgs -join ' ')`n$($output -join "`n")"
    }
}

function Write-FixtureFile {
    param([string]$RelativePath, [string]$Text)

    $path = Join-Path $fixture $RelativePath
    New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
    Set-Content -LiteralPath $path -Value $Text -Encoding utf8
}

function Invoke-Scan {
    $json = & $shellPath `
        -NoProfile `
        -ExecutionPolicy Bypass `
        -File $scanner `
        -VaultPath $fixture `
        -OutputFile $outputFile `
        -StateFile $stateFile `
        -Json
    if ($LASTEXITCODE -ne 0) {
        throw "Scanner failed with exit code $LASTEXITCODE"
    }
    return ($json | Out-String | ConvertFrom-Json)
}

function Assert-Count {
    param([object]$Scan, [string]$Kind, [int]$Expected)

    $actual = [int]$Scan.summary.$Kind
    if ($actual -ne $Expected) {
        throw "Expected $Kind=$Expected, got $actual"
    }
}

try {
    New-Item -ItemType Directory -Path $fixture -Force | Out-Null
    Invoke-FixtureGit -GitArgs @('init', '-b', 'main')
    Invoke-FixtureGit -GitArgs @('config', 'user.name', 'brainyard-test')
    Invoke-FixtureGit -GitArgs @('config', 'user.email', 'brainyard-test@localhost')

    Write-FixtureFile -RelativePath '10_domains\example\example.md' -Text "# Example`n"
    Invoke-FixtureGit -GitArgs @('add', '-A')
    Invoke-FixtureGit -GitArgs @('commit', '-m', 'initial')

    $first = Invoke-Scan
    Assert-Count -Scan $first -Kind 'total' -Expected 0

    & $shellPath -NoProfile -ExecutionPolicy Bypass -File $scanner `
        -VaultPath $fixture -StateFile $stateFile -AdvanceState | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw 'Initial checkpoint advance failed.'
    }

    Add-Content -LiteralPath (Join-Path $fixture '10_domains\example\example.md') -Value 'Update'
    Write-FixtureFile -RelativePath '20_tools\new-tool\new-tool.md' -Text "# New tool`n"
    $working = Invoke-Scan
    Assert-Count -Scan $working -Kind 'total' -Expected 2
    Assert-Count -Scan $working -Kind 'modified' -Expected 1
    Assert-Count -Scan $working -Kind 'added' -Expected 1

    Write-FixtureFile -RelativePath 'tools\not-markdown.txt' -Text 'control fixture'
    $candidatePaths = @($working.changes | ForEach-Object { $_.path })
    Invoke-FixtureGit -GitArgs (@('add', '-A', '--') + $candidatePaths)
    $stagedPaths = @(& $gitCommand -C $fixture diff --cached --name-only)
    if ($stagedPaths.Count -ne 2 -or $stagedPaths -contains 'tools/not-markdown.txt') {
        throw 'Only scanner-approved Markdown should be staged.'
    }
    Invoke-FixtureGit -GitArgs @('commit', '-m', 'approved changes')

    & $shellPath -NoProfile -ExecutionPolicy Bypass -File $scanner `
        -VaultPath $fixture -StateFile $stateFile -AdvanceState | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw 'Second checkpoint advance failed.'
    }
    $clean = Invoke-Scan
    Assert-Count -Scan $clean -Kind 'total' -Expected 0

    Add-Content -LiteralPath (Join-Path $fixture '10_domains\example\example.md') -Value 'Committed update'
    Invoke-FixtureGit -GitArgs @('add', '-A')
    Invoke-FixtureGit -GitArgs @('commit', '-m', 'external commit')
    $committed = Invoke-Scan
    Assert-Count -Scan $committed -Kind 'total' -Expected 1
    Assert-Count -Scan $committed -Kind 'modified' -Expected 1

    Write-FixtureFile -RelativePath '01_materials\raw.md' -Text "# Raw source`n"
    Add-Content -LiteralPath (Join-Path $fixture 'index.md') -Value '# Ignored index change'
    $ignored = Invoke-Scan
    Assert-Count -Scan $ignored -Kind 'total' -Expected 1
    if (@($ignored.changes | ForEach-Object { $_.path }) -contains '01_materials/raw.md') {
        throw 'Raw material must never enter the candidate list.'
    }

    $headBeforeFailedCheck = (& $gitCommand -C $fixture rev-parse HEAD | Out-String).Trim()
    foreach ($fileName in @('scan_changes.ps1', 'wiki_check.ps1', 'run_maintenance.ps1', 'maintenance-prompt.txt')) {
        Copy-Item -LiteralPath (Join-Path $repoRoot "tools\$fileName") -Destination (Join-Path $fixture "tools\$fileName")
    }
    Write-FixtureFile -RelativePath '10_domains\invalid\invalid.md' -Text "# Missing frontmatter`n"

    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & $shellPath -NoProfile -ExecutionPolicy Bypass -File (Join-Path $fixture 'tools\run_maintenance.ps1') -CheckOnly -IdleMinutes 0 | Out-Null
    $failedCheckExit = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorAction
    if ($failedCheckExit -eq 0) {
        throw 'A structural failure must not be reported as a successful check.'
    }

    $headAfterFailedCheck = (& $gitCommand -C $fixture rev-parse HEAD | Out-String).Trim()
    if ($headBeforeFailedCheck -ne $headAfterFailedCheck) {
        throw 'A failed structural check must not create a commit.'
    }

    Write-Output 'PASS: scanner, filtering, staging scope, history detection, and failed-check behavior are valid.'
}
finally {
    $resolvedFixture = [IO.Path]::GetFullPath($fixture)
    if (
        $resolvedFixture.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -and
        (Split-Path -Leaf $resolvedFixture).StartsWith('brainyard-scan-test-')
    ) {
        Remove-Item -LiteralPath $resolvedFixture -Recurse -Force -ErrorAction SilentlyContinue
    }
}
