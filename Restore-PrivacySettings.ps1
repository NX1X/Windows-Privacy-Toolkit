# Privacy Settings Restore Script
# Author: NX1X (www.nx1xlab.dev)
# Part of: NXTools (www.nx1xlab.dev/nxtools)
# License: MIT License
# Description: Restores Windows privacy settings to default (pre-toolkit) state
#
# ⚠️ DISCLAIMER: USE AT YOUR OWN RISK
# - This script restores settings to Windows defaults
# - This will RE-ENABLE telemetry and tracking
# - Only use if you want to undo the privacy hardening
# - Tested on Windows 11 (24H2)
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

Clear-Host

Write-Host "`n=== WINDOWS PRIVACY SETTINGS RESTORE ===" -ForegroundColor Cyan
Write-Host "Author: NX1X | www.nx1xlab.dev/nxtools`n" -ForegroundColor Gray

Write-Host "⚠️  WARNING: THIS WILL RESTORE TELEMETRY & TRACKING" -ForegroundColor Yellow
Write-Host "======================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "This script will UNDO all privacy hardening and restore:" -ForegroundColor Yellow
Write-Host "  - Windows Telemetry (will be RE-ENABLED)" -ForegroundColor Red
Write-Host "  - Activity History & Timeline" -ForegroundColor Red
Write-Host "  - Advertising ID" -ForegroundColor Red
Write-Host "  - Location Tracking" -ForegroundColor Red
Write-Host "  - Cortana & Web Search" -ForegroundColor Red
Write-Host "  - All tracking services" -ForegroundColor Red
Write-Host "  - Developer tool telemetry" -ForegroundColor Red
Write-Host "  - And more..." -ForegroundColor Red
Write-Host ""
Write-Host "Are you SURE you want to restore default (tracking-enabled) settings?" -ForegroundColor Yellow
Write-Host ""

$confirm = Read-Host "Type 'YES' to confirm restoration (anything else to cancel)"

if ($confirm -ne 'YES') {
    Write-Host "`nRestoration cancelled. No changes made." -ForegroundColor Green
    Write-Host "Your privacy settings remain hardened." -ForegroundColor Green
    exit 0
}

Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "Starting Settings Restoration..." -ForegroundColor Cyan
Write-Host "================================================================`n" -ForegroundColor Cyan

# Function to remove registry key/value
function Remove-RegistryValue {
    param(
        [string]$Path,
        [string]$Name
    )
    
    try {
        if (Test-Path $Path) {
            Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
        }
    } catch {
        # Silently continue if doesn't exist
    }
}

# Function to set registry value to default
function Set-RegistryDefault {
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

$restoredCount = 0

# ============================================================================
# WINDOWS TELEMETRY RESTORATION
# ============================================================================

Write-Host "[1/7] Restoring Windows Telemetry Settings..." -ForegroundColor Yellow

# Restore telemetry to Full (default)
Set-RegistryDefault -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 3
Write-Host "  [OK] Telemetry restored to Full (default)" -ForegroundColor Green
$restoredCount++

# Restore Activity History
Remove-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities"
Remove-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities"
Write-Host "  [OK] Activity History restored" -ForegroundColor Green
$restoredCount++

# Restore Advertising ID
Remove-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled"
Remove-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Name "DisabledByGroupPolicy"
Write-Host "  [OK] Advertising ID restored" -ForegroundColor Green
$restoredCount++

# Restore Location Tracking
Remove-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value"
Remove-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableLocation"
Write-Host "  [OK] Location tracking restored" -ForegroundColor Green
$restoredCount++

# Re-enable DiagTrack Service
try {
    Set-Service -Name DiagTrack -StartupType Automatic -ErrorAction SilentlyContinue
    Start-Service -Name DiagTrack -ErrorAction SilentlyContinue
    Write-Host "  [OK] DiagTrack service re-enabled" -ForegroundColor Green
    $restoredCount++
} catch {
    Write-Host "  [WARN] Could not re-enable DiagTrack" -ForegroundColor Yellow
}

# Restore Windows Spotlight
Remove-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsSpotlightFeatures"
Remove-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures"
Write-Host "  [OK] Windows Spotlight restored" -ForegroundColor Green
$restoredCount++

# Restore Tips & Suggestions
Remove-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338389Enabled"
Remove-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-353694Enabled"
Remove-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-353696Enabled"
Remove-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-310093Enabled"
Remove-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338388Enabled"
Remove-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SilentInstalledAppsEnabled"
Remove-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled"
Write-Host "  [OK] Tips & Suggestions restored" -ForegroundColor Green
$restoredCount++

# Restore Timeline
Remove-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed"
Write-Host "  [OK] Timeline restored" -ForegroundColor Green
$restoredCount++

# NOTE: Recall cannot be restored once removed
# If Recall was completely removed with payload, it cannot be re-enabled via this script
# You would need to reinstall Windows or use Windows Feature Restore to get it back
Write-Host "  [INFO] Recall: Cannot be restored (payload was removed - requires Windows reinstall)" -ForegroundColor Cyan

# Restore Copilot
Remove-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot"
Remove-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot"
Write-Host "  [OK] Copilot restored" -ForegroundColor Green
$restoredCount++

# Restore Feedback
Remove-RegistryValue -Path "HKCU:\Software\Microsoft\Siuf\Rules" -Name "NumberOfSIUFInPeriod"
Remove-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "DoNotShowFeedbackNotifications"
Write-Host "  [OK] Feedback notifications restored" -ForegroundColor Green
$restoredCount++

# Restore WiFi Sense
Remove-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" -Name "Value"
Remove-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" -Name "Value"
Write-Host "  [OK] WiFi Sense restored" -ForegroundColor Green
$restoredCount++

# Restore Web Search
Remove-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled"
Remove-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "CortanaConsent"
Remove-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "DisableWebSearch"
Write-Host "  [OK] Web Search restored" -ForegroundColor Green
$restoredCount++

# Restore Cloud Sync
Remove-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudStore" -Name "Store.CloudEnabled"
Remove-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Name "DisableSettingSync"
Remove-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Name "DisableSettingSyncUserOverride"
Remove-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Name "DisableApplicationSettingSync"
Remove-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Name "DisableAppSyncSettingSync"
Remove-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync" -Name "SyncPolicy"
Write-Host "  [OK] Cloud Sync restored" -ForegroundColor Green
$restoredCount++

# Restore Windows Update P2P (default is usually 1 or 2)
Remove-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode"
Write-Host "  [OK] Windows Update P2P restored to default" -ForegroundColor Green
$restoredCount++

# Restore Cortana
Remove-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana"
Remove-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortanaAboveLock"
Remove-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowSearchToUseLocation"
Remove-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "CortanaEnabled"
Write-Host "  [OK] Cortana restored" -ForegroundColor Green
$restoredCount++

# Restore Search History
Remove-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "HistoryViewEnabled"
Remove-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "DeviceHistoryEnabled"
Remove-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "ConnectedSearchUseWeb"
Write-Host "  [OK] Search History restored" -ForegroundColor Green
$restoredCount++

# Restore Edge Telemetry & Copilot
Remove-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "PersonalizationReportingEnabled"
Remove-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "UserFeedbackAllowed"
Remove-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "MetricsReportingEnabled"
Remove-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "SpotlightExperiencesAndRecommendationsEnabled"
Remove-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "EdgeCollectionsEnabled"
Remove-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "HubsSidebarEnabled"
Remove-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "CopilotEnabled"
Remove-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "CopilotPageContext"
Write-Host "  [OK] Edge telemetry & Copilot restored" -ForegroundColor Green
$restoredCount++

# Re-enable Tracking Services
Write-Host "  [INFO] Re-enabling tracking services..." -ForegroundColor Gray
$servicesToRestore = @('dmwappushservice', 'RetailDemo', 'WMPNetworkSvc', 'XblAuthManager', 'XblGameSave', 'MessagingService', 'RemoteRegistry')
$enabledCount = 0
foreach ($service in $servicesToRestore) {
    try {
        $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
        if ($svc) {
            Set-Service -Name $service -StartupType Manual -ErrorAction SilentlyContinue
            $enabledCount++
        }
    } catch {
        # Service doesn't exist, skip
    }
}
Write-Host "  [OK] Re-enabled $enabledCount services" -ForegroundColor Green
$restoredCount++

# Restore App Diagnostics
Remove-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\appDiagnostics" -Name "Value"
Write-Host "  [OK] App Diagnostics restored" -ForegroundColor Green
$restoredCount++

# Restore CEIP
Remove-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\SQMClient\Windows" -Name "CEIPEnable"
Remove-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\AppV\CEIP" -Name "CEIPEnable"
Write-Host "  [OK] CEIP restored" -ForegroundColor Green
$restoredCount++

# Restore Speech/Typing
Remove-RegistryValue -Path "HKCU:\Software\Microsoft\Personalization\Settings" -Name "AcceptedPrivacyPolicy"
Remove-RegistryValue -Path "HKCU:\Software\Microsoft\InputPersonalization" -Name "RestrictImplicitInkCollection"
Remove-RegistryValue -Path "HKCU:\Software\Microsoft\InputPersonalization" -Name "RestrictImplicitTextCollection"
Remove-RegistryValue -Path "HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore" -Name "HarvestContacts"
Write-Host "  [OK] Speech/Typing personalization restored" -ForegroundColor Green
$restoredCount++

# Restore Steps Recorder
Remove-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" -Name "DisableUAR"
Write-Host "  [OK] Steps Recorder restored" -ForegroundColor Green
$restoredCount++

# ============================================================================
# OFFICE TELEMETRY RESTORATION
# ============================================================================

Write-Host "`n[2/7] Restoring Microsoft Office Settings..." -ForegroundColor Yellow

# Remove all Office privacy restrictions
Remove-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\office\16.0\common\privacy" -Name "DisconnectedState"
Remove-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\office\16.0\common\privacy" -Name "UserContentDisabled"
Remove-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\office\16.0\common\privacy" -Name "DownloadContentDisabled"
Remove-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\office\16.0\common\privacy" -Name "ControllerConnectedServicesEnabled"
Remove-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\office\16.0\common\feedback" -Name "Enabled"
Remove-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\office\16.0\common\feedback" -Name "IncludeScreenshot"
Remove-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\office\16.0\common" -Name "QMEnable"
Remove-RegistryValue -Path "HKCU:\Software\Microsoft\Office\16.0\Common" -Name "sendcustomerdata"
Remove-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\office\16.0\osm" -Name "Enablelogging"
Remove-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\office\16.0\osm" -Name "EnableUpload"
Remove-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\office\16.0\common\general" -Name "DisableCloudFonts"
Remove-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\office\16.0\common\general" -Name "DisableBootToOfficeStart"
Remove-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\office\16.0\common" -Name "updatereliabilitydata"
Remove-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\office\16.0\common\linkedin" -Name "OfficeLinkedInDisabled"
Remove-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\office\16.0\common\intelligent services" -Name "disableservices"
Remove-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\office\16.0\common\research" -Name "ResearchEnabled"

Write-Host "  [OK] Office telemetry and features restored" -ForegroundColor Green
$restoredCount++

# ============================================================================
# DEVELOPER TOOLS TELEMETRY RESTORATION
# ============================================================================

Write-Host "`n[3/7] Restoring Developer Tools Telemetry..." -ForegroundColor Yellow

# Remove telemetry opt-out environment variables
[System.Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', $null, 'Machine')
[System.Environment]::SetEnvironmentVariable('VSCODE_TELEMETRY_OPTOUT', $null, 'Machine')
[System.Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT', $null, 'Machine')
[System.Environment]::SetEnvironmentVariable('WT_DISABLE_TELEMETRY', $null, 'Machine')

Write-Host "  [OK] Developer tools telemetry restored" -ForegroundColor Green
$restoredCount++

# ============================================================================
# ADVANCED HARDENING RESTORATION
# ============================================================================

Write-Host "`n[4/7] Restoring Scheduled Tasks..." -ForegroundColor Yellow

$tasksToRestore = @(
    "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
    "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
    "\Microsoft\Windows\Application Experience\StartupAppTask",
    "\Microsoft\Windows\Autochk\Proxy",
    "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
    "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
    "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector",
    "\Microsoft\Windows\Maintenance\WinSAT",
    "\Microsoft\Windows\PI\Sqm-Tasks",
    "\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem",
    "\Microsoft\Windows\Shell\FamilySafetyMonitor",
    "\Microsoft\Windows\Shell\FamilySafetyRefresh",
    "\Microsoft\Windows\Shell\FamilySafetyUpload",
    "\Microsoft\Windows\Windows Error Reporting\QueueReporting",
    "\Microsoft\Windows\CloudExperienceHost\CreateObjectTask"
)

$restoredTaskCount = 0
foreach ($task in $tasksToRestore) {
    try {
        $scheduledTask = Get-ScheduledTask -TaskPath (Split-Path $task -Parent) -TaskName (Split-Path $task -Leaf) -ErrorAction SilentlyContinue
        if ($scheduledTask) {
            Enable-ScheduledTask -TaskPath (Split-Path $task -Parent) -TaskName (Split-Path $task -Leaf) -ErrorAction SilentlyContinue | Out-Null
            $restoredTaskCount++
        }
    } catch {
        # Task doesn't exist
    }
}

Write-Host "  [OK] Re-enabled $restoredTaskCount telemetry scheduled tasks" -ForegroundColor Green
$restoredCount++

# ============================================================================
# HOSTS FILE RESTORATION
# ============================================================================

Write-Host "`n[5/7] Checking Hosts File..." -ForegroundColor Yellow

$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
if (Test-Path $hostsPath) {
    $hostsContent = Get-Content -Path $hostsPath -ErrorAction SilentlyContinue
    $marker = "# Windows Privacy Toolkit - Telemetry Blocking"
    
    if ($hostsContent -contains $marker) {
        Write-Host "  [INFO] Found Privacy Toolkit entries in hosts file" -ForegroundColor Yellow
        Write-Host "  [INFO] Creating backup before restoration..." -ForegroundColor Gray
        
        # Backup current hosts file
        Copy-Item -Path $hostsPath -Destination "$hostsPath.restore_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')" -Force
        
        # Remove all lines after marker
        $newHostsContent = @()
        $skipMode = $false
        foreach ($line in $hostsContent) {
            if ($line -eq $marker) {
                $skipMode = $true
                continue
            }
            if ($line -match "^127\.0\.0\.1.*telemetry" -or $line -match "^127\.0\.0\.1.*vortex" -or $line -match "^127\.0\.0\.1.*watson") {
                continue
            }
            if (-not $skipMode) {
                $newHostsContent += $line
            }
        }
        
        Set-Content -Path $hostsPath -Value $newHostsContent -Encoding ASCII
        
        # Flush DNS
        ipconfig /flushdns | Out-Null
        
        Write-Host "  [OK] Hosts file cleaned (telemetry blocks removed)" -ForegroundColor Green
        Write-Host "  [OK] DNS cache flushed" -ForegroundColor Green
        $restoredCount++
    } else {
        Write-Host "  [OK] No Privacy Toolkit entries found in hosts file" -ForegroundColor Green
    }
}

# ============================================================================
# FIREWALL RULES RESTORATION
# ============================================================================

Write-Host "`n[6/7] Removing Firewall Rules..." -ForegroundColor Yellow

try {
    $firewallRule = Get-NetFirewallRule -DisplayName "Windows Privacy Toolkit - Block Telemetry" -ErrorAction SilentlyContinue
    if ($firewallRule) {
        Remove-NetFirewallRule -DisplayName "Windows Privacy Toolkit - Block Telemetry" -ErrorAction SilentlyContinue
        Write-Host "  [OK] Privacy Toolkit firewall rule removed" -ForegroundColor Green
        $restoredCount++
    } else {
        Write-Host "  [OK] No Privacy Toolkit firewall rules found" -ForegroundColor Green
    }
} catch {
    Write-Host "  [OK] No firewall rules to remove" -ForegroundColor Green
}

# ============================================================================
# FINAL AUDIT
# ============================================================================

Write-Host "`n[7/7] Running Final Audit..." -ForegroundColor Yellow
Write-Host "  [INFO] You can verify restoration by running Privacy-Audit.ps1" -ForegroundColor Gray
Write-Host "  [INFO] Settings should now show as [WARN] or [BAD] (tracking enabled)" -ForegroundColor Gray

# ============================================================================
# SUMMARY
# ============================================================================

Write-Host "`n=== RESTORATION COMPLETE ===" -ForegroundColor Cyan

Write-Host "`n[OK] Privacy settings restored to Windows defaults!" -ForegroundColor Green
Write-Host "`nWhat was restored:" -ForegroundColor Cyan
Write-Host "  - Windows Telemetry: RE-ENABLED (Full level)" -ForegroundColor Red
Write-Host "  - Tracking Services: RE-ENABLED" -ForegroundColor Red
Write-Host "  - Activity History: RE-ENABLED" -ForegroundColor Red
Write-Host "  - Advertising ID: RE-ENABLED" -ForegroundColor Red
Write-Host "  - Location Tracking: RE-ENABLED" -ForegroundColor Red
Write-Host "  - Cortana & Search: RE-ENABLED" -ForegroundColor Red
Write-Host "  - Office Telemetry: RE-ENABLED" -ForegroundColor Red
Write-Host "  - Developer Tools Telemetry: RE-ENABLED" -ForegroundColor Red
Write-Host "  - Scheduled Tasks: $restoredTaskCount tasks re-enabled" -ForegroundColor White
Write-Host "  - Hosts File: Cleaned (if modified)" -ForegroundColor White
Write-Host "  - Firewall Rules: Removed (if created)" -ForegroundColor White

Write-Host "`nIMPORTANT:" -ForegroundColor Yellow
Write-Host "  - Run Privacy-Audit.ps1 to verify restoration" -ForegroundColor Gray
Write-Host "  - A restart is recommended for all changes to take effect" -ForegroundColor Gray
Write-Host "  - Your system is now back to default Windows privacy settings" -ForegroundColor Gray
Write-Host "  - Telemetry and tracking are now ACTIVE" -ForegroundColor Red

Write-Host "`nTo re-apply privacy hardening, run:" -ForegroundColor Cyan
Write-Host "  .\Install.ps1" -ForegroundColor White
Write-Host "    or" -ForegroundColor Gray
Write-Host "  .\Disable-WindowsTelemetry.ps1" -ForegroundColor White

Write-Host "`nMore info: https://github.com/NX1X/Windows-Privacy-Toolkit" -ForegroundColor DarkGray
Write-Host "Docs: https://docs.nx1xlab.dev | Blog: https://blog.nx1xlab.dev`n" -ForegroundColor DarkGray

# Keep window open if run via context menu
if ($Host.Name -eq 'ConsoleHost') {
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
