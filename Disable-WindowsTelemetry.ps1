# Windows Telemetry Hardening Script
# Author: NX1X (www.nx1xlab.dev)
# Part of: NXTools (www.nx1xlab.dev/nxtools)
# License: MIT License
# Description: Disable Windows 10/11 telemetry, tracking, and privacy-invasive features
#
# ⚠️ DISCLAIMER: USE AT YOUR OWN RISK
# - Tested on Windows 11 (24H2)
# - Should work on Windows 10 (NOT tested)
# - Modifies registry and system settings
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

Write-Host "`n=== WINDOWS PRIVACY HARDENING ===" -ForegroundColor Cyan
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

Write-Host "[1/10] Disabling Windows Telemetry..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0
Write-Host "  [OK] Telemetry set to Security/Off level" -ForegroundColor Green

Write-Host "`n[2/10] Disabling Activity History..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Value 0
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Value 0
Write-Host "  [OK] Activity History disabled" -ForegroundColor Green

Write-Host "`n[3/10] Disabling Advertising ID..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Name "DisabledByGroupPolicy" -Value 1
Write-Host "  [OK] Advertising ID disabled" -ForegroundColor Green

Write-Host "`n[4/10] Disabling Location Tracking..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Value "Deny" -Type "String"
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableLocation" -Value 1
Write-Host "  [OK] Location tracking disabled" -ForegroundColor Green

Write-Host "`n[5/10] Stopping and Disabling DiagTrack Service..." -ForegroundColor Yellow
try {
    Stop-Service -Name DiagTrack -Force -ErrorAction SilentlyContinue
    Set-Service -Name DiagTrack -StartupType Disabled -ErrorAction SilentlyContinue
    Write-Host "  [OK] DiagTrack service stopped and disabled" -ForegroundColor Green
} catch {
    Write-Host "  [WARN] DiagTrack service not found or already disabled" -ForegroundColor Yellow
}

Write-Host "`n[6/10] Disabling Windows Spotlight..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsSpotlightFeatures" -Value 1
Set-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1
Write-Host "  [OK] Windows Spotlight disabled" -ForegroundColor Green

Write-Host "`n[7/10] Disabling Tips & Suggestions..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338389Enabled" -Value 0
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-353694Enabled" -Value 0
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-353696Enabled" -Value 0
Write-Host "  [OK] Tips & Suggestions disabled" -ForegroundColor Green

Write-Host "`n[8/10] Disabling Timeline..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Value 0
Write-Host "  [OK] Timeline disabled" -ForegroundColor Green

Write-Host "`n[9/10] Disabling Copilot..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 1
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 1
Write-Host "  [OK] Copilot disabled" -ForegroundColor Green

Write-Host "`n[10/10] Disabling Feedback Notifications..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Siuf\Rules" -Name "NumberOfSIUFInPeriod" -Value 0
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "DoNotShowFeedbackNotifications" -Value 1
Write-Host "  [OK] Feedback notifications disabled" -ForegroundColor Green

Write-Host "`n=== HARDENING COMPLETE ===" -ForegroundColor Cyan
Write-Host "`n[OK] Windows privacy settings hardened successfully!" -ForegroundColor Green
Write-Host "`nRun Privacy-Audit.ps1 to verify changes" -ForegroundColor Gray
Write-Host "A restart is recommended for all changes to take effect" -ForegroundColor Gray
Write-Host "`nMore info: https://github.com/NX1X/Windows-Privacy-Toolkit" -ForegroundColor DarkGray
Write-Host "Docs: https://docs.nx1xlab.dev | Blog: https://blog.nx1xlab.dev`n" -ForegroundColor DarkGray

# Keep window open if run via context menu
if ($Host.Name -eq 'ConsoleHost') {
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
