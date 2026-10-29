[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$Uninstall,
    [string]$TaskPrefix = 'BrainyardMaintenance',
    [string]$RunDailyAt = '00:00',
    [int]$StartupDelayMinutes = 5
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($env:OS -ne 'Windows_NT') {
    throw 'This installer targets Windows Task Scheduler.'
}

$vault = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $PSScriptRoot 'run_maintenance.ps1'
$dailyTask = "$TaskPrefix-Daily"
$loginTask = "$TaskPrefix-Login"

if ($Uninstall) {
    foreach ($taskName in @($dailyTask, $loginTask)) {
        if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
            if ($PSCmdlet.ShouldProcess($taskName, 'Unregister scheduled task')) {
                Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
            }
        }
    }
    Write-Output "Removed Brainyard scheduled tasks: $dailyTask, $loginTask"
    exit 0
}

$pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
$shellPath = if ($pwsh) {
    $pwsh.Source
} else {
    Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
}
$arguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$runner`""
$action = New-ScheduledTaskAction -Execute $shellPath -Argument $arguments -WorkingDirectory $vault
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -MultipleInstances IgnoreNew

$dailyTrigger = New-ScheduledTaskTrigger -Daily -At $RunDailyAt
$loginTrigger = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
try {
    $loginTrigger.Delay = "PT${StartupDelayMinutes}M"
}
catch {
    Write-Warning 'The Task Scheduler engine did not expose a logon delay; the login task will start immediately.'
}

if ($PSCmdlet.ShouldProcess($dailyTask, 'Register daily Brainyard maintenance')) {
    Register-ScheduledTask `
        -TaskName $dailyTask `
        -Action $action `
        -Trigger $dailyTrigger `
        -Principal $principal `
        -Settings $settings `
        -Description 'Run Brainyard low-risk maintenance once per day.' `
        -Force | Out-Null
}

if ($PSCmdlet.ShouldProcess($loginTask, 'Register login Brainyard maintenance')) {
    Register-ScheduledTask `
        -TaskName $loginTask `
        -Action $action `
        -Trigger $loginTrigger `
        -Principal $principal `
        -Settings $settings `
        -Description 'Recover missed Brainyard maintenance after login.' `
        -Force | Out-Null
}

Write-Output "Installed Brainyard scheduled tasks: $dailyTask, $loginTask"
Write-Output "Vault: $vault"
