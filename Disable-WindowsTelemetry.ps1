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

Write-Host "[1/25] Disabling Windows Telemetry..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0
Write-Host "  [OK] Telemetry set to Security/Off level" -ForegroundColor Green

Write-Host "`n[2/25] Disabling Activity History..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Value 0
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Value 0
Write-Host "  [OK] Activity History disabled" -ForegroundColor Green

Write-Host "`n[3/25] Disabling Advertising ID..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Name "DisabledByGroupPolicy" -Value 1
Write-Host "  [OK] Advertising ID disabled" -ForegroundColor Green

Write-Host "`n[4/25] Disabling Location Tracking..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Value "Deny" -Type "String"
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableLocation" -Value 1
Write-Host "  [OK] Location tracking disabled" -ForegroundColor Green

Write-Host "`n[5/25] Stopping and Disabling DiagTrack Service..." -ForegroundColor Yellow
try {
    Stop-Service -Name DiagTrack -Force -ErrorAction SilentlyContinue
    Set-Service -Name DiagTrack -StartupType Disabled -ErrorAction SilentlyContinue
    Write-Host "  [OK] DiagTrack service stopped and disabled" -ForegroundColor Green
} catch {
    Write-Host "  [WARN] DiagTrack service not found or already disabled" -ForegroundColor Yellow
}

Write-Host "`n[6/25] Disabling Windows Spotlight..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsSpotlightFeatures" -Value 1
Set-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1
Write-Host "  [OK] Windows Spotlight disabled" -ForegroundColor Green

Write-Host "`n[7/25] Disabling Tips & Suggestions..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338389Enabled" -Value 0
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-353694Enabled" -Value 0
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-353696Enabled" -Value 0
Write-Host "  [OK] Tips & Suggestions disabled" -ForegroundColor Green

Write-Host "`n[8/25] Disabling Timeline..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Value 0
Write-Host "  [OK] Timeline disabled" -ForegroundColor Green

Write-Host "`n[9/25] Disabling Copilot..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 1
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 1
Write-Host "  [OK] Copilot disabled" -ForegroundColor Green

Write-Host "`n[10/25] Removing Recall (Windows 11 AI Snapshot Feature)..." -ForegroundColor Yellow
try {
    # Check if Recall feature exists
    $recallCheck = Dism /Online /Get-FeatureInfo /FeatureName:Recall 2>&1 | Select-String "State"

    if ($recallCheck) {
        # Completely remove Recall with payload
        Write-Host "  [INFO] Removing Recall feature and payload..." -ForegroundColor Cyan
        $dismResult = Dism /Online /Disable-Feature /FeatureName:Recall /Remove /NoRestart 2>&1

        if ($LASTEXITCODE -eq 0 -or $dismResult -match "successfully") {
            Write-Host "  [OK] Recall removed completely (payload deleted)" -ForegroundColor Green
        } else {
            Write-Host "  [WARN] Recall disable attempted but may need restart" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [INFO] Recall not available on this system (Win10 or older Win11)" -ForegroundColor Gray
    }
} catch {
    Write-Host "  [INFO] Recall not available on this system" -ForegroundColor Gray
}

Write-Host "`n[11/25] Disabling Feedback Notifications..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Siuf\Rules" -Name "NumberOfSIUFInPeriod" -Value 0
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "DoNotShowFeedbackNotifications" -Value 1
Write-Host "  [OK] Feedback notifications disabled" -ForegroundColor Green

Write-Host "`n[12/25] Disabling WiFi Sense..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" -Name "Value" -Value 0
Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" -Name "Value" -Value 0
Write-Host "  [OK] WiFi Sense disabled" -ForegroundColor Green

Write-Host "`n[13/25] Disabling Web Search in Start Menu..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "CortanaConsent" -Value 0
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "DisableWebSearch" -Value 1
Write-Host "  [OK] Web Search in Start Menu disabled" -ForegroundColor Green

Write-Host "`n[14/25] Disabling Cloud Sync for Start Menu..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudStore" -Name "Store.CloudEnabled" -Value 0
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Name "DisableSettingSync" -Value 2
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Name "DisableSettingSyncUserOverride" -Value 1
Write-Host "  [OK] Cloud Sync for Start Menu disabled" -ForegroundColor Green

Write-Host "`n[15/25] Configuring Windows Update P2P (LAN-only)..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode" -Value 1
Write-Host "  [OK] Windows Update P2P set to LAN-only (no internet upload)" -ForegroundColor Green

Write-Host "`n[16/25] Disabling Cortana..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortanaAboveLock" -Value 0
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowSearchToUseLocation" -Value 0
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "CortanaEnabled" -Value 0
Write-Host "  [OK] Cortana disabled" -ForegroundColor Green

Write-Host "`n[17/25] Disabling Search History & Bing Integration..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "HistoryViewEnabled" -Value 0
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "DeviceHistoryEnabled" -Value 0
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "ConnectedSearchUseWeb" -Value 0
Write-Host "  [OK] Search History & Bing Integration disabled" -ForegroundColor Green

Write-Host "`n[18/25] Disabling Microsoft Edge Telemetry & Copilot..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "PersonalizationReportingEnabled" -Value 0
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "UserFeedbackAllowed" -Value 0
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "MetricsReportingEnabled" -Value 0
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "SpotlightExperiencesAndRecommendationsEnabled" -Value 0
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "EdgeCollectionsEnabled" -Value 0
# Disable Edge Copilot (Sidebar AI)
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "HubsSidebarEnabled" -Value 0
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "CopilotEnabled" -Value 0
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "CopilotPageContext" -Value 0
Write-Host "  [OK] Edge telemetry & Copilot disabled (security features preserved)" -ForegroundColor Green

Write-Host "`n[19/25] Stopping & Disabling Tracking Services..." -ForegroundColor Yellow
$servicesToDisable = @('dmwappushservice', 'RetailDemo', 'WMPNetworkSvc', 'XblAuthManager', 'XblGameSave', 'MessagingService')
$disabledCount = 0
foreach ($service in $servicesToDisable) {
    try {
        $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
        if ($svc) {
            Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
            Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
            $disabledCount++
        }
    } catch {
        # Service doesn't exist, skip silently
    }
}
Write-Host "  [OK] Disabled $disabledCount tracking services" -ForegroundColor Green

Write-Host "`n[20/25] Disabling App Diagnostics Access..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\appDiagnostics" -Name "Value" -Value "Deny" -Type "String"
Write-Host "  [OK] App Diagnostics access disabled" -ForegroundColor Green

Write-Host "`n[21/25] Disabling Customer Experience Improvement Program..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\SQMClient\Windows" -Name "CEIPEnable" -Value 0
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\AppV\CEIP" -Name "CEIPEnable" -Value 0
Write-Host "  [OK] CEIP disabled" -ForegroundColor Green

Write-Host "`n[22/25] Disabling Windows Store Suggestions..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SilentInstalledAppsEnabled" -Value 0
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled" -Value 0
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-310093Enabled" -Value 0
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338388Enabled" -Value 0
Write-Host "  [OK] Store suggestions disabled" -ForegroundColor Green

Write-Host "`n[23/25] Disabling Speech, Inking & Typing Personalization..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Personalization\Settings" -Name "AcceptedPrivacyPolicy" -Value 0
Set-RegistryValue -Path "HKCU:\Software\Microsoft\InputPersonalization" -Name "RestrictImplicitInkCollection" -Value 1
Set-RegistryValue -Path "HKCU:\Software\Microsoft\InputPersonalization" -Name "RestrictImplicitTextCollection" -Value 1
Set-RegistryValue -Path "HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore" -Name "HarvestContacts" -Value 0
Write-Host "  [OK] Speech, Inking & Typing personalization disabled" -ForegroundColor Green

Write-Host "`n[24/25] Disabling Steps Recorder & Remote Registry..." -ForegroundColor Yellow
try {
    Stop-Service -Name RemoteRegistry -Force -ErrorAction SilentlyContinue
    Set-Service -Name RemoteRegistry -StartupType Disabled -ErrorAction SilentlyContinue
    Write-Host "  [OK] Remote Registry service disabled" -ForegroundColor Green
} catch {
    Write-Host "  [WARN] Remote Registry service not found" -ForegroundColor Yellow
}
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" -Name "DisableUAR" -Value 1
Write-Host "  [OK] Steps Recorder disabled" -ForegroundColor Green

Write-Host "`n[25/25] Disabling Microsoft Account Sync Settings..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Name "DisableApplicationSettingSync" -Value 2
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Name "DisableAppSyncSettingSync" -Value 2
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync" -Name "SyncPolicy" -Value 5
Write-Host "  [OK] Microsoft Account sync settings disabled" -ForegroundColor Green

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
