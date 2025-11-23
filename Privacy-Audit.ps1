# Windows Privacy Audit Script
# Author: NX1X (www.nx1xlab.dev)
# Part of: NXTools (www.nx1xlab.dev/nxtools)
# License: MIT License
# Description: Comprehensive audit of Windows 10/11 privacy settings
#
# ⚠️ INFO: This is a READ-ONLY audit script
# - Safe to run (does not modify anything)
# - Tested on Windows 11 (24H2)
# - Compatible with Windows 10
#
# Repository: https://github.com/NX1X/Windows-Privacy-Toolkit
# Documentation: https://docs.nx1xlab.dev
# Blog: https://blog.nx1xlab.dev

# Self-elevate the script if required (recommended for full audit access)
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    if ([Environment]::GetCommandLineArgs().Contains('-NonInteractive')) {
        Write-Warning "Running without administrator privileges. Some checks may be incomplete."
    } else {
        try {
            $scriptPath = if ($PSCommandPath) { $PSCommandPath } else { $MyInvocation.MyCommand.Definition }
            Start-Process PowerShell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"Set-Location -LiteralPath '$((Get-Item $scriptPath).DirectoryName)'; & '$scriptPath'`""
            exit 0
        } catch {
            Write-Warning "Could not elevate to Administrator. Running with limited access."
        }
    }
}

# Fix console encoding for special characters
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "`n=== WINDOWS PRIVACY AUDIT ===" -ForegroundColor Cyan
Write-Host "Author: NX1X | www.nx1xlab.dev/nxtools`n" -ForegroundColor Gray

# 1. Telemetry
Write-Host "[Telemetry Settings]" -ForegroundColor Yellow
try {
    $telemetry = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name AllowTelemetry -ErrorAction Stop).AllowTelemetry
    Write-Host "Telemetry Level: $telemetry $(if($telemetry -eq 0){'[OK] (Security/Off)'}else{'[BAD] (Should be 0)'})"
} catch {
    Write-Host "Telemetry: [BAD] Not configured (likely enabled)" -ForegroundColor Red
}

# 2. Recall (Windows 11 only)
Write-Host "`n[Recall Status - Windows 11]" -ForegroundColor Yellow
try {
    $recall = Dism /Online /Get-FeatureInfo /FeatureName:Recall 2>&1 | Select-String "State"
    if($recall -match "DisabledWithPayloadRemoved") {
        Write-Host "Recall: [OK] Disabled with Payload Removed (Best)" -ForegroundColor Green
    } elseif($recall -match "Disabled") {
        Write-Host "Recall: [WARN] Disabled (but payload still present)" -ForegroundColor Yellow
    } elseif($recall -match "Enabled") {
        Write-Host "Recall: [BAD] Enabled" -ForegroundColor Red
    } else {
        Write-Host "Recall: [INFO] Not available on this system" -ForegroundColor Gray
    }
} catch {
    Write-Host "Recall: [INFO] Not available on this system" -ForegroundColor Gray
}

# 3. Copilot
Write-Host "`n[Copilot Status]" -ForegroundColor Yellow
try {
    $copilot = (Get-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -Name TurnOffWindowsCopilot -ErrorAction Stop).TurnOffWindowsCopilot
    Write-Host "Copilot: $(if($copilot -eq 1){'[OK] Disabled'}else{'[BAD] Enabled'})"
} catch {
    Write-Host "Copilot: [WARN] Not configured (may be enabled)" -ForegroundColor Yellow
}

# 4. Activity History
Write-Host "`n[Activity History]" -ForegroundColor Yellow
try {
    $activity = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name PublishUserActivities -ErrorAction Stop).PublishUserActivities
    Write-Host "Activity History: $(if($activity -eq 0){'[OK] Disabled'}else{'[BAD] Enabled'})"
} catch {
    Write-Host "Activity History: [WARN] Not configured (likely enabled)" -ForegroundColor Yellow
}

# 5. Advertising ID
Write-Host "`n[Advertising ID]" -ForegroundColor Yellow
try {
    $adID = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name Enabled -ErrorAction Stop).Enabled
    Write-Host "Advertising ID: $(if($adID -eq 0){'[OK] Disabled'}else{'[BAD] Enabled'})"
} catch {
    Write-Host "Advertising ID: [WARN] Not configured (likely enabled)" -ForegroundColor Yellow
}

# 6. Location Tracking
Write-Host "`n[Location Services]" -ForegroundColor Yellow
try {
    $location = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name Value -ErrorAction Stop).Value
    Write-Host "Location: $(if($location -eq 'Deny'){'[OK] Disabled'}else{'[BAD] Enabled'})"
} catch {
    Write-Host "Location: [WARN] Not configured (likely enabled)" -ForegroundColor Yellow
}

# 7. Diagnostic Data Viewer
Write-Host "`n[DiagTrack Service]" -ForegroundColor Yellow
$diagtrack = Get-Service -Name DiagTrack -ErrorAction SilentlyContinue
if($diagtrack) {
    Write-Host "DiagTrack: $($diagtrack.Status) $(if($diagtrack.Status -eq 'Stopped'){'[OK]'}else{'[BAD] (Should be stopped)'})"
} else {
    Write-Host "DiagTrack: [INFO] Service not found" -ForegroundColor Gray
}

# 8. Windows Spotlight
Write-Host "`n[Windows Spotlight]" -ForegroundColor Yellow
try {
    $spotlight = (Get-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\CloudContent" -Name DisableWindowsSpotlightFeatures -ErrorAction Stop).DisableWindowsSpotlightFeatures
    Write-Host "Windows Spotlight: $(if($spotlight -eq 1){'[OK] Disabled'}else{'[BAD] Enabled'})"
} catch {
    Write-Host "Windows Spotlight: [WARN] Not configured (likely enabled)" -ForegroundColor Yellow
}

# 9. Suggestions & Tips
Write-Host "`n[Suggestions & Tips]" -ForegroundColor Yellow
try {
    $tips = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name SubscribedContent-338389Enabled -ErrorAction Stop).'SubscribedContent-338389Enabled'
    Write-Host "Tips & Suggestions: $(if($tips -eq 0){'[OK] Disabled'}else{'[BAD] Enabled'})"
} catch {
    Write-Host "Tips & Suggestions: [WARN] Not configured (likely enabled)" -ForegroundColor Yellow
}

# 10. Timeline
Write-Host "`n[Timeline]" -ForegroundColor Yellow
try {
    $timeline = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name EnableActivityFeed -ErrorAction Stop).EnableActivityFeed
    Write-Host "Timeline: $(if($timeline -eq 0){'[OK] Disabled'}else{'[BAD] Enabled'})"
} catch {
    Write-Host "Timeline: [WARN] Not configured (likely enabled)" -ForegroundColor Yellow
}

# 11. PowerShell Telemetry
Write-Host "`n[PowerShell Telemetry]" -ForegroundColor Yellow
$psTelemetry = [System.Environment]::GetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', 'Machine')
if($psTelemetry -eq '1') {
    Write-Host "PowerShell Telemetry: [OK] Disabled" -ForegroundColor Green
} else {
    Write-Host "PowerShell Telemetry: [BAD] Enabled (not opted out)" -ForegroundColor Red
}

# 12. Microsoft Office Telemetry
Write-Host "`n[Microsoft Office Telemetry]" -ForegroundColor Yellow
try {
    $officePrivacy = Get-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\office\16.0\common\privacy" -ErrorAction Stop
    $disconnected = $officePrivacy.DisconnectedState
    $userContent = $officePrivacy.UserContentDisabled

    if($disconnected -eq 2 -and $userContent -eq 2) {
        Write-Host "Office Telemetry: [OK] Disabled" -ForegroundColor Green
    } else {
        Write-Host "Office Telemetry: [WARN] Partially configured" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Office Telemetry: [WARN] Not configured (likely enabled)" -ForegroundColor Yellow
}

Write-Host "`n=== AUDIT COMPLETE ===" -ForegroundColor Cyan
Write-Host "`nTo fix issues, run the hardening scripts:" -ForegroundColor Gray
Write-Host "   .\Disable-WindowsTelemetry.ps1" -ForegroundColor Gray
Write-Host "   .\Disable-OfficeTelemetry.ps1" -ForegroundColor Gray
Write-Host "   .\Disable-PowerShellTelemetry.ps1" -ForegroundColor Gray
Write-Host "`nMore info: https://github.com/NX1X/Windows-Privacy-Toolkit" -ForegroundColor DarkGray
Write-Host "Docs: https://docs.nx1xlab.dev | Blog: https://blog.nx1xlab.dev`n" -ForegroundColor DarkGray

# Keep window open if run via context menu
if ($Host.Name -eq 'ConsoleHost') {
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
