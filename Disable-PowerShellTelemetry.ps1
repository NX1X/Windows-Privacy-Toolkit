# PowerShell Telemetry Hardening Script
# Author: NX1X (www.nx1xlab.dev)
# Part of: NXTools (www.nx1xlab.dev/nxtools)
# License: MIT License
# Description: Disable PowerShell telemetry collection
#
# ⚠️ DISCLAIMER: USE AT YOUR OWN RISK
# - Tested on Windows 11 (PowerShell 5.1)
# - Should work on Windows 10 (NOT tested)
# - Modifies system environment variables
#
# Repository: https://github.com/NX1X/Windows-Privacy-Toolkit
# Documentation: https://docs.nx1xlab.dev
# Blog: https://blog.nx1xlab.dev

# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    if ([Environment]::GetCommandLineArgs().Contains('-NonInteractive')) {
        Write-Error "This script requires administrator privileges. Please run as Administrator."
        exit 1
    }
    try {
        $scriptPath = if ($PSCommandPath) { $PSCommandPath } else { $MyInvocation.MyCommand.Definition }
        $escapedDir = (Split-Path $scriptPath -Parent).Replace("'", "''")
        $escapedPath = $scriptPath.Replace("'", "''")
        Start-Process PowerShell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"Set-Location -LiteralPath '$escapedDir'; & '$escapedPath'`""
        exit 0
    } catch {
        Write-Error "Failed to elevate to Administrator. Please run this script as Administrator."
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# Fix console encoding for special characters
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "`n=== POWERSHELL PRIVACY HARDENING ===" -ForegroundColor Cyan
Write-Host "Author: NX1X | www.nx1xlab.dev/nxtools`n" -ForegroundColor Gray

Write-Host "[1/4] Disabling PowerShell Telemetry..." -ForegroundColor Yellow

# Set system-wide environment variable to opt-out of PowerShell telemetry
[System.Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', '1', 'Machine')

# Verify
$telemetryStatus = [System.Environment]::GetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', 'Machine')

if ($telemetryStatus -eq '1') {
    Write-Host "  [OK] PowerShell telemetry disabled successfully" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] Failed to disable PowerShell telemetry" -ForegroundColor Red
    exit 1
}

Write-Host "`n[2/4] Disabling VS Code Telemetry..." -ForegroundColor Yellow

[System.Environment]::SetEnvironmentVariable('VSCODE_TELEMETRY_OPTOUT', '1', 'Machine')

$vscodeStatus = [System.Environment]::GetEnvironmentVariable('VSCODE_TELEMETRY_OPTOUT', 'Machine')
if ($vscodeStatus -eq '1') {
    Write-Host "  [OK] VS Code telemetry disabled" -ForegroundColor Green
} else {
    Write-Host "  [WARN] VS Code telemetry opt-out may not have been set" -ForegroundColor Yellow
}

Write-Host "`n[3/4] Disabling .NET Core Telemetry..." -ForegroundColor Yellow

[System.Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT', '1', 'Machine')

$dotnetStatus = [System.Environment]::GetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT', 'Machine')
if ($dotnetStatus -eq '1') {
    Write-Host "  [OK] .NET Core telemetry disabled" -ForegroundColor Green
} else {
    Write-Host "  [WARN] .NET Core telemetry opt-out may not have been set" -ForegroundColor Yellow
}

Write-Host "`n[4/4] Disabling Windows Terminal Telemetry..." -ForegroundColor Yellow

[System.Environment]::SetEnvironmentVariable('WT_DISABLE_TELEMETRY', '1', 'Machine')

$wtStatus = [System.Environment]::GetEnvironmentVariable('WT_DISABLE_TELEMETRY', 'Machine')
if ($wtStatus -eq '1') {
    Write-Host "  [OK] Windows Terminal telemetry disabled" -ForegroundColor Green
} else {
    Write-Host "  [WARN] Windows Terminal telemetry opt-out may not have been set" -ForegroundColor Yellow
}

Write-Host "`n=== POWERSHELL & DEVELOPER TOOLS HARDENING COMPLETE ===" -ForegroundColor Cyan
Write-Host "`n[OK] Developer tool privacy settings configured!" -ForegroundColor Green
Write-Host "`nRun Privacy-Audit.ps1 to verify changes" -ForegroundColor Gray
Write-Host "Restart PowerShell for changes to take effect" -ForegroundColor Gray
Write-Host "`nMore info: https://github.com/NX1X/Windows-Privacy-Toolkit" -ForegroundColor DarkGray
Write-Host "Docs: https://docs.nx1xlab.dev | Blog: https://blog.nx1xlab.dev`n" -ForegroundColor DarkGray

# Keep window open if run via context menu
if ($Host.Name -eq 'ConsoleHost') {
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
