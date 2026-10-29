[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$IncludeWarnings
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$vault = Split-Path -Parent $PSScriptRoot
$markdownFiles = @(
    Get-ChildItem -LiteralPath $vault -Recurse -File -Filter '*.md' -Force |
        Where-Object {
            $_.FullName -notmatch '\\(\.git|\.obsidian|\.claudian|tools\\maintenance)\\'
        }
)

$relativePaths = @{}
foreach ($file in $markdownFiles) {
    $relativePaths[$file.FullName.Substring($vault.Length + 1)] = $file.FullName
}

$issues = [System.Collections.Generic.List[object]]::new()
$warnings = [System.Collections.Generic.List[object]]::new()
$inbound = @{}
$allowedTypes = @('hub', 'concept', 'tool', 'project', 'source', 'process', 'index', 'template', 'navigation', 'log')
$allowedStatuses = @('active', 'draft', 'archived')

function Add-Issue {
    param([string]$Code, [string]$File, [string]$Message)
    $issues.Add([pscustomobject]@{ Code = $Code; File = $File; Message = $Message })
}

function Add-Warning {
    param([string]$Code, [string]$File, [string]$Message)
    $warnings.Add([pscustomobject]@{ Code = $Code; File = $File; Message = $Message })
}

function Test-RequiresFrontmatter {
    param([string]$RelativePath)

    return (
        $RelativePath.StartsWith('00_navigation\') -or
        $RelativePath.StartsWith('10_domains\') -or
        $RelativePath.StartsWith('20_tools\') -or
        $RelativePath.StartsWith('90_templates\') -or
        $RelativePath -in @('index.md', 'log.md')
    )
}

foreach ($file in $markdownFiles) {
    $relative = $file.FullName.Substring($vault.Length + 1)
    $text = [IO.File]::ReadAllText($file.FullName, [Text.Encoding]::UTF8)

    if (Test-RequiresFrontmatter -RelativePath $relative) {
        if ($text -notmatch '^---\r?\n([\s\S]*?)\r?\n---') {
            Add-Issue -Code 'FRONTMATTER_MISSING' -File $relative -Message 'Missing frontmatter'
        }
        else {
            $frontmatter = $Matches[1]
            $keys = @(
                [regex]::Matches($frontmatter, '(?m)^([^\s:#][^:\r\n]*):') |
                    ForEach-Object { $_.Groups[1].Value.Trim() }
            )
            $required = @('type', 'status', 'updated', 'tags')
            $allowedExtra = @('permalink')
            $missing = @($required | Where-Object { $_ -notin $keys })
            $extra = @($keys | Where-Object { $_ -notin $required -and $_ -notin $allowedExtra })
            if ($missing.Count -gt 0) {
                Add-Issue -Code 'FRONTMATTER_FIELDS' -File $relative -Message ('Missing: ' + ($missing -join ', '))
            }
            if ($extra.Count -gt 0) {
                Add-Issue -Code 'FRONTMATTER_EXTRA' -File $relative -Message ('Unexpected: ' + ($extra -join ', '))
            }

            if ($frontmatter -match '(?m)^type:\s*(.+?)\s*$') {
                $type = $Matches[1]
                if ($type -notin $allowedTypes) {
                    Add-Issue -Code 'TYPE_INVALID' -File $relative -Message $type
                }
            }
            if ($frontmatter -match '(?m)^status:\s*(.+?)\s*$') {
                $status = $Matches[1]
                if ($status -notin $allowedStatuses) {
                    Add-Issue -Code 'STATUS_INVALID' -File $relative -Message $status
                }
            }
        }
    }

    if (
        -not $relative.StartsWith('01_materials\') -and
        -not $relative.StartsWith('90_templates\')
    ) {
        $withoutFences = [regex]::Replace($text, '(?s)```.*?```', '')
        $withoutCode = [regex]::Replace($withoutFences, '`[^`\r\n]*`', '')
        foreach ($match in [regex]::Matches($withoutCode, '\[\[([^\]\r\n]+?)\]\]')) {
            $target = ($match.Groups[1].Value -split '\|')[0]
            $target = ($target -split '#')[0].TrimEnd('\').Trim()
            if ([string]::IsNullOrWhiteSpace($target)) { continue }
            $resolved = $false
            if ([IO.Path]::GetExtension($target)) {
                $resolved = $relativePaths.ContainsKey($target.Replace('/', '\')) -or
                    (Test-Path -LiteralPath (Join-Path $vault $target))
            }
            else {
                $markdownTarget = $target.Replace('/', '\') + '.md'
                $folderPageTarget = $target.Replace('/', '\') + '\' + (Split-Path -Leaf $target) + '.md'
                $resolved = $relativePaths.ContainsKey($markdownTarget) -or
                    $relativePaths.ContainsKey($folderPageTarget)
            }
            if ($resolved) {
                $normalized = $target.Replace('/', '\')
                if (-not [IO.Path]::GetExtension($normalized)) {
                    $direct = $normalized + '.md'
                    $folderPage = $normalized + '\' + (Split-Path -Leaf $normalized) + '.md'
                    $normalized = if ($relativePaths.ContainsKey($direct)) { $direct } else { $folderPage }
                }
                $inbound[$normalized] = 1 + $(if ($inbound.ContainsKey($normalized)) { $inbound[$normalized] } else { 0 })
            }
            else {
                Add-Issue -Code 'DEAD_LINK' -File $relative -Message $target
            }
        }
    }
}

$contentFiles = @(
    $markdownFiles | Where-Object {
        $relative = $_.FullName.Substring($vault.Length + 1)
        $relative.StartsWith('10_domains\') -or $relative.StartsWith('20_tools\')
    }
)
foreach ($file in $contentFiles) {
    $relative = $file.FullName.Substring($vault.Length + 1)
    $text = [IO.File]::ReadAllText($file.FullName, [Text.Encoding]::UTF8)
    if ($text -notmatch '(?m)^#\s+\S') {
        Add-Issue -Code 'H1_MISSING' -File $relative -Message 'Content page requires one H1 heading'
    }
    if (-not $inbound.ContainsKey($relative) -or $inbound[$relative] -lt 1) {
        Add-Issue -Code 'ORPHAN' -File $relative -Message 'No inbound links'
    }
}

$allFiles = @(
    Get-ChildItem -LiteralPath $vault -Recurse -File -Force |
        Where-Object {
            $_.FullName -notmatch '\\(\.git|\.obsidian|\.claudian|tools\\maintenance)\\' -and
            $_.FullName -notmatch '\\01_materials\\'
        }
)
foreach ($file in $allFiles) {
    $relative = $file.FullName.Substring($vault.Length + 1)
    if ($file.Length -eq 0) {
        Add-Issue -Code 'EMPTY_FILE' -File $relative -Message 'Empty file'
    }
    if ($file.Name -match '(?i)(\.tmp$|~$|\.bak$|\.swp$|^Thumbs\.db$|^\.DS_Store$)') {
        Add-Issue -Code 'TEMP_FILE' -File $relative -Message 'Temporary file'
    }
}

$standardNames = @('README.md', 'CONTRIBUTING.md', 'SECURITY.md', 'CODE_OF_CONDUCT.md', 'CHANGELOG.md')
$duplicateNames = @(
    $allFiles |
        Where-Object { $_.Name -notin $standardNames } |
        Group-Object Name |
        Where-Object Count -gt 1 |
        ForEach-Object {
            [pscustomobject]@{
                Name = $_.Name
                Count = $_.Count
                Paths = @($_.Group | ForEach-Object { $_.FullName.Substring($vault.Length + 1) })
            }
        }
)

$result = [pscustomobject]@{
    Vault = $vault
    MarkdownFiles = $markdownFiles.Count
    ContentFiles = $contentFiles.Count
    Issues = $issues.Count
    Warnings = $warnings.Count
    IssueItems = $issues
    WarningItems = $warnings
    DuplicateBasenames = $duplicateNames
}

if ($Json) {
    $result | ConvertTo-Json -Depth 6
}
else {
    [pscustomobject]@{
        Vault = $result.Vault
        MarkdownFiles = $result.MarkdownFiles
        ContentFiles = $result.ContentFiles
        Issues = $result.Issues
        Warnings = $result.Warnings
    } | Format-List
    if ($issues.Count -gt 0) {
        $issues | Format-Table -AutoSize
    }
    if ($IncludeWarnings -and $warnings.Count -gt 0) {
        $warnings | Format-Table -AutoSize
    }
}

if ($issues.Count -gt 0) { exit 1 }
