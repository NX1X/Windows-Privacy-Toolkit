# Windows Privacy Audit Script
# Author: NX1X (www.nx1xlab.dev)
# Part of: NXTools (www.nx1xlab.dev/nxtools)
# License: MIT License
# Description: Comprehensive audit of Windows 10/11 privacy settings with report generation
#
# ⚠️ INFO: This is a READ-ONLY audit script
# - Safe to run (does not modify anything)
# - Tested on Windows 11 (24H2)
# - Compatible with Windows 10
# - Generates detailed text report
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
            $escapedDir = (Split-Path $scriptPath -Parent).Replace("'", "''")
            $escapedPath = $scriptPath.Replace("'", "''")
            Start-Process PowerShell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"Set-Location -LiteralPath '$escapedDir'; & '$escapedPath'`""
            exit 0
        } catch {
            Write-Warning "Could not elevate to Administrator. Running with limited access."
        }
    }
}

# Fix console encoding for special characters
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

# Initialize report string
$reportContent = ""
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$reportTimestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

# Function to add to both console and report
function Write-AuditLine {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
    $script:reportContent += "$Message`n"
}

Write-AuditLine "`n=== WINDOWS PRIVACY AUDIT ===" "Cyan"
Write-AuditLine "Author: NX1X | www.nx1xlab.dev/nxtools`n" "Gray"
Write-AuditLine "Audit Date: $timestamp" "Gray"
Write-AuditLine "Computer: $env:COMPUTERNAME" "Gray"
Write-AuditLine "Windows Version: $((Get-CimInstance Win32_OperatingSystem).Caption)`n" "Gray"

$goodCount = 0
$badCount = 0
$warnCount = 0

# 1. Telemetry
Write-AuditLine "[Telemetry Settings]" "Yellow"
try {
    $telemetry = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name AllowTelemetry -ErrorAction Stop).AllowTelemetry
    if($telemetry -eq 0) {
        Write-AuditLine "Telemetry Level: $telemetry [OK] (Security/Off)" "Green"
        $goodCount++
    } else {
        Write-AuditLine "Telemetry Level: $telemetry [BAD] (Should be 0)" "Red"
        $badCount++
    }
} catch {
    Write-AuditLine "Telemetry: [BAD] Not configured (likely enabled)" "Red"
    $badCount++
}

# 2. Recall (Windows 11 only)
Write-AuditLine "`n[Recall Status - Windows 11]" "Yellow"
try {
    $recall = Dism /Online /Get-FeatureInfo /FeatureName:Recall 2>&1 | Select-String "State"
    if($recall -match "DisabledWithPayloadRemoved") {
        Write-AuditLine "Recall: [OK] Disabled with Payload Removed (Best)" "Green"
        $goodCount++
    } elseif($recall -match "Disabled") {
        Write-AuditLine "Recall: [WARN] Disabled (but payload still present)" "Yellow"
        $warnCount++
    } elseif($recall -match "Enabled") {
        Write-AuditLine "Recall: [BAD] Enabled" "Red"
        $badCount++
    } else {
        Write-AuditLine "Recall: [INFO] Not available on this system" "Gray"
    }
} catch {
    Write-AuditLine "Recall: [INFO] Not available on this system" "Gray"
}

# 3. Copilot
Write-AuditLine "`n[Copilot Status]" "Yellow"
try {
    $copilot = (Get-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -Name TurnOffWindowsCopilot -ErrorAction Stop).TurnOffWindowsCopilot
    if($copilot -eq 1) {
        Write-AuditLine "Copilot: [OK] Disabled" "Green"
        $goodCount++
    } else {
        Write-AuditLine "Copilot: [BAD] Enabled" "Red"
        $badCount++
    }
} catch {
    Write-AuditLine "Copilot: [WARN] Not configured (may be enabled)" "Yellow"
    $warnCount++
}

# 4. Activity History
Write-AuditLine "`n[Activity History]" "Yellow"
try {
    $activity = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name PublishUserActivities -ErrorAction Stop).PublishUserActivities
    if($activity -eq 0) {
        Write-AuditLine "Activity History: [OK] Disabled" "Green"
        $goodCount++
    } else {
        Write-AuditLine "Activity History: [BAD] Enabled" "Red"
        $badCount++
    }
} catch {
    Write-AuditLine "Activity History: [WARN] Not configured (likely enabled)" "Yellow"
    $warnCount++
}

# 5. Advertising ID
Write-AuditLine "`n[Advertising ID]" "Yellow"
try {
    $adID = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name Enabled -ErrorAction Stop).Enabled
    if($adID -eq 0) {
        Write-AuditLine "Advertising ID: [OK] Disabled" "Green"
        $goodCount++
    } else {
        Write-AuditLine "Advertising ID: [BAD] Enabled" "Red"
        $badCount++
    }
} catch {
    Write-AuditLine "Advertising ID: [WARN] Not configured (likely enabled)" "Yellow"
    $warnCount++
}

# 6. Location Tracking
Write-AuditLine "`n[Location Services]" "Yellow"
try {
    $location = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name Value -ErrorAction Stop).Value
    if($location -eq 'Deny') {
        Write-AuditLine "Location: [OK] Disabled" "Green"
        $goodCount++
    } else {
        Write-AuditLine "Location: [BAD] Enabled" "Red"
        $badCount++
    }
} catch {
    Write-AuditLine "Location: [WARN] Not configured (likely enabled)" "Yellow"
    $warnCount++
}

# 7. Diagnostic Data Viewer
Write-AuditLine "`n[DiagTrack Service]" "Yellow"
$diagtrack = Get-Service -Name DiagTrack -ErrorAction SilentlyContinue
if($diagtrack) {
    if($diagtrack.Status -eq 'Stopped') {
        Write-AuditLine "DiagTrack: $($diagtrack.Status) [OK]" "Green"
        $goodCount++
    } else {
        Write-AuditLine "DiagTrack: $($diagtrack.Status) [BAD] (Should be stopped)" "Red"
        $badCount++
    }
} else {
    Write-AuditLine "DiagTrack: [INFO] Service not found" "Gray"
}

# 8. Windows Spotlight
Write-AuditLine "`n[Windows Spotlight]" "Yellow"
try {
    $spotlight = (Get-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\CloudContent" -Name DisableWindowsSpotlightFeatures -ErrorAction Stop).DisableWindowsSpotlightFeatures
    if($spotlight -eq 1) {
        Write-AuditLine "Windows Spotlight: [OK] Disabled" "Green"
        $goodCount++
    } else {
        Write-AuditLine "Windows Spotlight: [BAD] Enabled" "Red"
        $badCount++
    }
} catch {
    Write-AuditLine "Windows Spotlight: [WARN] Not configured (likely enabled)" "Yellow"
    $warnCount++
}

# 9. Suggestions & Tips
Write-AuditLine "`n[Suggestions & Tips]" "Yellow"
try {
    $tips = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name SubscribedContent-338389Enabled -ErrorAction Stop).'SubscribedContent-338389Enabled'
    if($tips -eq 0) {
        Write-AuditLine "Tips & Suggestions: [OK] Disabled" "Green"
        $goodCount++
    } else {
        Write-AuditLine "Tips & Suggestions: [BAD] Enabled" "Red"
        $badCount++
    }
} catch {
    Write-AuditLine "Tips & Suggestions: [WARN] Not configured (likely enabled)" "Yellow"
    $warnCount++
}

# 10. Timeline
Write-AuditLine "`n[Timeline]" "Yellow"
try {
    $timeline = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name EnableActivityFeed -ErrorAction Stop).EnableActivityFeed
    if($timeline -eq 0) {
        Write-AuditLine "Timeline: [OK] Disabled" "Green"
        $goodCount++
    } else {
        Write-AuditLine "Timeline: [BAD] Enabled" "Red"
        $badCount++
    }
} catch {
    Write-AuditLine "Timeline: [WARN] Not configured (likely enabled)" "Yellow"
    $warnCount++
}

# 11. PowerShell Telemetry
Write-AuditLine "`n[PowerShell Telemetry]" "Yellow"
$psTelemetry = [System.Environment]::GetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', 'Machine')
if($psTelemetry -eq '1') {
    Write-AuditLine "PowerShell Telemetry: [OK] Disabled" "Green"
    $goodCount++
} else {
    Write-AuditLine "PowerShell Telemetry: [BAD] Enabled (not opted out)" "Red"
    $badCount++
}

# 12. Microsoft Office Telemetry
Write-AuditLine "`n[Microsoft Office Telemetry]" "Yellow"
try {
    $officePrivacy = Get-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\office\16.0\common\privacy" -ErrorAction Stop
    $disconnected = $officePrivacy.DisconnectedState
    $userContent = $officePrivacy.UserContentDisabled

    if($disconnected -eq 2 -and $userContent -eq 2) {
        Write-AuditLine "Office Telemetry: [OK] Disabled" "Green"
        $goodCount++
    } else {
        Write-AuditLine "Office Telemetry: [WARN] Partially configured" "Yellow"
        $warnCount++
    }
} catch {
    Write-AuditLine "Office Telemetry: [WARN] Not configured (likely enabled)" "Yellow"
    $warnCount++
}

# 13. WiFi Sense
Write-AuditLine "`n[WiFi Sense]" "Yellow"
try {
    $wifiSense = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" -Name Value -ErrorAction Stop).Value
    if($wifiSense -eq 0) {
        Write-AuditLine "WiFi Sense: [OK] Disabled" "Green"
        $goodCount++
    } else {
        Write-AuditLine "WiFi Sense: [BAD] Enabled" "Red"
        $badCount++
    }
} catch {
    Write-AuditLine "WiFi Sense: [INFO] Not configured (feature may not exist on this system)" "Gray"
}

# 14. Windows Update P2P
Write-AuditLine "`n[Windows Update P2P Sharing]" "Yellow"
try {
    $wudo = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name DODownloadMode -ErrorAction Stop).DODownloadMode
    if($wudo -eq 0) {
        Write-AuditLine "WUDO: [OK] Completely Disabled" "Green"
        $goodCount++
    } elseif($wudo -eq 1) {
        Write-AuditLine "WUDO: [OK] LAN-only (no internet upload)" "Green"
        $goodCount++
    } else {
        Write-AuditLine "WUDO: [WARN] Set to $wudo (Should be 0 or 1)" "Yellow"
        $warnCount++
    }
} catch {
    Write-AuditLine "WUDO: [WARN] Not configured (likely enabled with internet upload)" "Yellow"
    $warnCount++
}

# 15. Cortana Status
Write-AuditLine "`n[Cortana Status]" "Yellow"
try {
    $cortana = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name AllowCortana -ErrorAction Stop).AllowCortana
    if($cortana -eq 0) {
        Write-AuditLine "Cortana: [OK] Disabled" "Green"
        $goodCount++
    } else {
        Write-AuditLine "Cortana: [BAD] Enabled" "Red"
        $badCount++
    }
} catch {
    Write-AuditLine "Cortana: [WARN] Not configured (likely enabled)" "Yellow"
    $warnCount++
}

# 16. Web Search in Start Menu
Write-AuditLine "`n[Web Search in Start Menu]" "Yellow"
try {
    $bingSearch = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name BingSearchEnabled -ErrorAction Stop).BingSearchEnabled
    if($bingSearch -eq 0) {
        Write-AuditLine "Bing Search: [OK] Disabled" "Green"
        $goodCount++
    } else {
        Write-AuditLine "Bing Search: [BAD] Enabled" "Red"
        $badCount++
    }
} catch {
    Write-AuditLine "Bing Search: [WARN] Not configured (likely enabled)" "Yellow"
    $warnCount++
}

# 17. App Diagnostics Permission
Write-AuditLine "`n[App Diagnostics Access]" "Yellow"
try {
    $appDiag = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\appDiagnostics" -Name Value -ErrorAction Stop).Value
    if($appDiag -eq 'Deny') {
        Write-AuditLine "App Diagnostics: [OK] Disabled" "Green"
        $goodCount++
    } else {
        Write-AuditLine "App Diagnostics: [BAD] Enabled" "Red"
        $badCount++
    }
} catch {
    Write-AuditLine "App Diagnostics: [WARN] Not configured (likely enabled)" "Yellow"
    $warnCount++
}

# 18. Active Telemetry Services
Write-AuditLine "`n[Telemetry Services Status]" "Yellow"
$telemetryServices = @('DiagTrack', 'dmwappushservice', 'RetailDemo')
$runningCount = 0
foreach ($svc in $telemetryServices) {
    $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($service -and $service.Status -eq 'Running') {
        $runningCount++
    }
}
if($runningCount -eq 0) {
    Write-AuditLine "Telemetry Services: [OK] All stopped ($runningCount running)" "Green"
    $goodCount++
} else {
    Write-AuditLine "Telemetry Services: [WARN] $runningCount services still running" "Yellow"
    $warnCount++
}

# 19. Edge Telemetry
Write-AuditLine "`n[Microsoft Edge Telemetry]" "Yellow"
try {
    $edgeTelemetry = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name MetricsReportingEnabled -ErrorAction Stop).MetricsReportingEnabled
    if($edgeTelemetry -eq 0) {
        Write-AuditLine "Edge Telemetry: [OK] Disabled" "Green"
        $goodCount++
    } else {
        Write-AuditLine "Edge Telemetry: [BAD] Enabled" "Red"
        $badCount++
    }
} catch {
    Write-AuditLine "Edge Telemetry: [WARN] Not configured (likely enabled)" "Yellow"
    $warnCount++
}

# 20. SmartScreen for Apps
Write-AuditLine "`n[SmartScreen for Store Apps]" "Yellow"
try {
    $smartScreen = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AppHost" -Name EnableWebContentEvaluation -ErrorAction Stop).EnableWebContentEvaluation
    if($smartScreen -eq 0) {
        Write-AuditLine "SmartScreen: [WARN] Disabled (Security Feature)" "Yellow"
        $warnCount++
    } else {
        Write-AuditLine "SmartScreen: [OK] Enabled (Protects Security)" "Green"
        $goodCount++
    }
} catch {
    Write-AuditLine "SmartScreen: [INFO] Not configured" "Gray"
}

# 21. Speech & Typing Personalization
Write-AuditLine "`n[Speech & Typing Personalization]" "Yellow"
try {
    $speechTyping = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Personalization\Settings" -Name AcceptedPrivacyPolicy -ErrorAction Stop).AcceptedPrivacyPolicy
    if($speechTyping -eq 0) {
        Write-AuditLine "Speech/Typing: [OK] Disabled" "Green"
        $goodCount++
    } else {
        Write-AuditLine "Speech/Typing: [BAD] Enabled" "Red"
        $badCount++
    }
} catch {
    Write-AuditLine "Speech/Typing: [WARN] Not configured (likely enabled)" "Yellow"
    $warnCount++
}

# 22. VS Code Telemetry
Write-AuditLine "`n[VS Code Telemetry]" "Yellow"
$vscodeTelemetry = [System.Environment]::GetEnvironmentVariable('VSCODE_TELEMETRY_OPTOUT', 'Machine')
if($vscodeTelemetry -eq '1') {
    Write-AuditLine "VS Code Telemetry: [OK] Disabled" "Green"
    $goodCount++
} else {
    Write-AuditLine "VS Code Telemetry: [WARN] Not disabled" "Yellow"
    $warnCount++
}

# 23. .NET Core Telemetry
Write-AuditLine "`n[.NET Core Telemetry]" "Yellow"
$dotnetTelemetry = [System.Environment]::GetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT', 'Machine')
if($dotnetTelemetry -eq '1') {
    Write-AuditLine ".NET Core Telemetry: [OK] Disabled" "Green"
    $goodCount++
} else {
    Write-AuditLine ".NET Core Telemetry: [WARN] Not disabled" "Yellow"
    $warnCount++
}

# 24. Windows Terminal Telemetry
Write-AuditLine "`n[Windows Terminal Telemetry]" "Yellow"
$wtTelemetry = [System.Environment]::GetEnvironmentVariable('WT_DISABLE_TELEMETRY', 'Machine')
if($wtTelemetry -eq '1') {
    Write-AuditLine "Windows Terminal Telemetry: [OK] Disabled" "Green"
    $goodCount++
} else {
    Write-AuditLine "Windows Terminal Telemetry: [WARN] Not disabled" "Yellow"
    $warnCount++
}

# Summary
$totalChecks = $goodCount + $badCount + $warnCount
Write-AuditLine "`n=== AUDIT SUMMARY ===" "Cyan"
Write-AuditLine "Total Checks: $totalChecks" "White"
Write-AuditLine "[OK] Good (Privacy Protected): $goodCount" "Green"
Write-AuditLine "[BAD] Bad (Privacy Risk): $badCount" "Red"
Write-AuditLine "[WARN] Warnings: $warnCount" "Yellow"

# Calculate privacy score
if ($totalChecks -gt 0) {
    $privacyScore = [math]::Round(($goodCount / $totalChecks) * 100, 1)
    Write-AuditLine "`nPrivacy Score: $privacyScore% " "Cyan"
    
    if ($privacyScore -ge 80) {
        Write-AuditLine "Status: Excellent Privacy Protection! 🛡️" "Green"
    } elseif ($privacyScore -ge 60) {
        Write-AuditLine "Status: Good Privacy Protection" "Green"
    } elseif ($privacyScore -ge 40) {
        Write-AuditLine "Status: Moderate Privacy Protection" "Yellow"
    } else {
        Write-AuditLine "Status: Poor Privacy Protection - Run hardening scripts!" "Red"
    }
}

Write-AuditLine "`n=== AUDIT COMPLETE ===" "Cyan"
Write-AuditLine "`nTo fix issues, run the hardening scripts:" "Gray"
Write-AuditLine "   .\Disable-WindowsTelemetry.ps1" "Gray"
Write-AuditLine "   .\Disable-OfficeTelemetry.ps1" "Gray"
Write-AuditLine "   .\Disable-PowerShellTelemetry.ps1" "Gray"
Write-AuditLine "   .\Disable-AdvancedTelemetry.ps1 (optional - advanced hardening)" "Gray"

# Generate report file
$reportPath = ".\Privacy-Audit-Report_$reportTimestamp.txt"
$reportContent | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "`n[OK] Detailed report saved to: $reportPath" -ForegroundColor Green

Write-AuditLine "`nMore info: https://github.com/NX1X/Windows-Privacy-Toolkit" "DarkGray"
Write-AuditLine "Docs: https://docs.nx1xlab.dev | Blog: https://blog.nx1xlab.dev`n" "DarkGray"

# Keep window open if run via context menu
if ($Host.Name -eq 'ConsoleHost') {
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
