# Microsoft Office Telemetry Hardening Script
# Author: NX1X (www.nx1xlab.dev)
# Part of: NXTools (www.nx1xlab.dev/nxtools)
# License: MIT License
# Description: Disable Microsoft Office telemetry and connected services
#
# ⚠️ DISCLAIMER: USE AT YOUR OWN RISK
# - Tested on Windows 11 with Office 365
# - Should work on Windows 10 (NOT tested)
# - Modifies Office registry settings
# - Create a restore point before running
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
        Start-Process PowerShell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"Set-Location -LiteralPath '$((Get-Item $scriptPath).DirectoryName)'; & '$scriptPath'`""
        exit 0
    } catch {
        Write-Error "Failed to elevate to Administrator. Please run this script as Administrator."
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# Fix console encoding for special characters
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Clear screen for clean output
Clear-Host

Write-Host "`n=== MICROSOFT OFFICE PRIVACY HARDENING ===" -ForegroundColor Cyan
Write-Host "Author: NX1X | www.nx1xlab.dev/nxtools`n" -ForegroundColor Gray

# Function to create registry path if it doesn't exist
function Set-RegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [string]$Type = "DWord"
    )
    
    if (!(Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force
}

Write-Host "[1/3] Disabling Office Telemetry & Connected Services..." -ForegroundColor Yellow

# Office 2016/2019/365 privacy settings (version 16.0)
Set-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\office\16.0\common\privacy" -Name "DisconnectedState" -Value 2
Set-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\office\16.0\common\privacy" -Name "UserContentDisabled" -Value 2
Set-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\office\16.0\common\privacy" -Name "DownloadContentDisabled" -Value 2
Set-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\office\16.0\common\privacy" -Name "ControllerConnectedServicesEnabled" -Value 2

Write-Host "  [OK] Office telemetry disabled" -ForegroundColor Green

Write-Host "`n[2/3] Disabling Office Feedback..." -ForegroundColor Yellow

Set-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\office\16.0\common\feedback" -Name "Enabled" -Value 0
Set-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\office\16.0\common\feedback" -Name "IncludeScreenshot" -Value 0

Write-Host "  [OK] Office feedback disabled" -ForegroundColor Green

Write-Host "`n[3/3] Disabling Office Customer Experience Improvement Program..." -ForegroundColor Yellow

Set-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\office\16.0\common" -Name "QMEnable" -Value 0
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Office\16.0\Common" -Name "sendcustomerdata" -Value 0

Write-Host "  [OK] Customer Experience Improvement Program disabled" -ForegroundColor Green

Write-Host "`n=== OFFICE HARDENING COMPLETE ===" -ForegroundColor Cyan
Write-Host "`n[OK] Microsoft Office privacy settings hardened successfully!" -ForegroundColor Green
Write-Host "`nRun Privacy-Audit.ps1 to verify changes" -ForegroundColor Gray
Write-Host "Restart Office applications for changes to take effect" -ForegroundColor Gray
Write-Host "`nMore info: https://github.com/NX1X/Windows-Privacy-Toolkit" -ForegroundColor DarkGray
Write-Host "Docs: https://docs.nx1xlab.dev | Blog: https://blog.nx1xlab.dev`n" -ForegroundColor DarkGray

# Keep window open if run via context menu
if ($Host.Name -eq 'ConsoleHost') {
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
