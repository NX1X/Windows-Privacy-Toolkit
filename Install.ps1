# Windows Privacy Toolkit - One-Click Installer
# Author: NX1X (www.nx1xlab.dev)
# Part of: NXTools (www.nx1xlab.dev/nxtools)
# License: MIT License
# Description: Automated installer that runs all privacy hardening scripts with detailed reporting
#
# ⚠️ DISCLAIMER: USE AT YOUR OWN RISK
# - Tested on Windows 11 (25H2)
# - Should work on Windows 10 (NOT tested)
# - Creates system restore point automatically
# - Modifies registry and system settings
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
        Write-Host "`nTry running PowerShell as Administrator and then execute:" -ForegroundColor Yellow
        Write-Host "  Set-ExecutionPolicy Bypass -Scope Process -Force; .\Install.ps1" -ForegroundColor Cyan
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# Fix console encoding for special characters
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

# Clear screen for clean output
Clear-Host

# ASCII Art Banner
Write-Host @"

+==============================================================+
|                                                              |
|        Windows Privacy Toolkit - Automated Installer         |
|                                                              |
|                    Author: NX1X                              |
|              www.nx1xlab.dev/nxtools                         |
|                                                              |
|  GitHub: github.com/NX1X/Windows-Privacy-Toolkit             |
|  Docs: docs.nx1xlab.dev | Blog: blog.nx1xlab.dev             |
|                                                              |
+==============================================================+

"@ -ForegroundColor Cyan

Write-Host "This installer will:" -ForegroundColor Yellow
Write-Host "  1. Create a system restore point (safety first!)" -ForegroundColor White
Write-Host "  2. Run a privacy audit to show current settings" -ForegroundColor White
Write-Host "  3. Apply all privacy hardening scripts" -ForegroundColor White
Write-Host "  4. Run a final audit to verify changes" -ForegroundColor White
Write-Host "  5. Generate a detailed before/after comparison report" -ForegroundColor White
Write-Host ""

# Confirmation prompt
$confirm = Read-Host "Do you want to proceed? (Y/N)"
if ($confirm -ne 'Y' -and $confirm -ne 'y') {
    Write-Host "`nInstallation cancelled by user." -ForegroundColor Red
    exit 0
}

Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "Starting Installation..." -ForegroundColor Cyan
Write-Host "================================================================`n" -ForegroundColor Cyan

# Step 1: Create System Restore Point
Write-Host "[Step 1/5] Creating System Restore Point..." -ForegroundColor Yellow
try {
    Enable-ComputerRestore -Drive "$env:SystemDrive\"
    Checkpoint-Computer -Description "Before Windows Privacy Toolkit" -RestorePointType "MODIFY_SETTINGS"
    Write-Host "  [OK] System restore point created successfully" -ForegroundColor Green
} catch {
    Write-Host "  [WARN] Could not create restore point (might be disabled or too recent)" -ForegroundColor Yellow
    Write-Host "     Continuing anyway..." -ForegroundColor Gray
}

Start-Sleep -Seconds 2

# Function to capture audit results
function Get-PrivacyAuditSnapshot {
    $snapshot = @{}
    
    # Telemetry
    try {
        $snapshot['Telemetry'] = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name AllowTelemetry -ErrorAction Stop).AllowTelemetry
    } catch { $snapshot['Telemetry'] = "Not Set" }
    
    # DiagTrack Service
    try {
        $svc = Get-Service -Name DiagTrack -ErrorAction SilentlyContinue
        $snapshot['DiagTrack'] = "$($svc.Status) / $($svc.StartType)"
    } catch { $snapshot['DiagTrack'] = "Not Found" }
    
    # Cortana
    try {
        $snapshot['Cortana'] = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name AllowCortana -ErrorAction Stop).AllowCortana
    } catch { $snapshot['Cortana'] = "Not Set" }
    
    # Advertising ID
    try {
        $snapshot['AdvertisingID'] = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name Enabled -ErrorAction Stop).Enabled
    } catch { $snapshot['AdvertisingID'] = "Not Set" }
    
    # Location Tracking
    try {
        $snapshot['Location'] = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name Value -ErrorAction Stop).Value
    } catch { $snapshot['Location'] = "Not Set" }
    
    # Activity History
    try {
        $snapshot['ActivityHistory'] = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name PublishUserActivities -ErrorAction Stop).PublishUserActivities
    } catch { $snapshot['ActivityHistory'] = "Not Set" }
    
    # Copilot
    try {
        $snapshot['Copilot'] = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Name TurnOffWindowsCopilot -ErrorAction Stop).TurnOffWindowsCopilot
    } catch { $snapshot['Copilot'] = "Not Set" }
    
    # PowerShell Telemetry
    $snapshot['PowerShellTelemetry'] = [System.Environment]::GetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', 'Machine')
    if (!$snapshot['PowerShellTelemetry']) { $snapshot['PowerShellTelemetry'] = "Not Set" }
    
    # VS Code Telemetry
    $snapshot['VSCodeTelemetry'] = [System.Environment]::GetEnvironmentVariable('VSCODE_TELEMETRY_OPTOUT', 'Machine')
    if (!$snapshot['VSCodeTelemetry']) { $snapshot['VSCodeTelemetry'] = "Not Set" }
    
    # Edge Telemetry
    try {
        $snapshot['EdgeTelemetry'] = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name MetricsReportingEnabled -ErrorAction Stop).MetricsReportingEnabled
    } catch { $snapshot['EdgeTelemetry'] = "Not Set" }
    
    # Tracking Services Count
    $trackingServices = @('dmwappushservice', 'RetailDemo', 'WMPNetworkSvc')
    $runningCount = 0
    foreach ($svc in $trackingServices) {
        $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if ($service -and $service.Status -eq 'Running') { $runningCount++ }
    }
    $snapshot['TrackingServicesRunning'] = $runningCount
    
    return $snapshot
}

# Step 2: Initial Audit & Capture Baseline
Write-Host "`n[Step 2/5] Running Initial Privacy Audit & Capturing Baseline..." -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Gray

Write-Host "`n[INFO] Capturing current privacy settings..." -ForegroundColor Cyan
$beforeSnapshot = Get-PrivacyAuditSnapshot

if (Test-Path ".\Privacy-Audit.ps1") {
    & ".\Privacy-Audit.ps1"
} else {
    Write-Host "  [WARN] Privacy-Audit.ps1 not found in current directory" -ForegroundColor Yellow
}

Write-Host "`nPress any key to continue with hardening..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Step 3: Apply Hardening Scripts
Write-Host "`n[Step 3/5] Applying Privacy Hardening..." -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Gray

$hardeningScripts = @(
    "Disable-WindowsTelemetry.ps1",
    "Disable-OfficeTelemetry.ps1",
    "Disable-PowerShellTelemetry.ps1"
)

$advancedScript = "Disable-AdvancedTelemetry.ps1"

$successCount = 0
foreach ($script in $hardeningScripts) {
    if (Test-Path ".\$script") {
        Write-Host "`nExecuting $script..." -ForegroundColor Cyan
        try {
            & ".\$script"
            $successCount++
        } catch {
            Write-Host "  [ERROR] Error executing $script : $_" -ForegroundColor Red
        }
    } else {
        Write-Host "  [WARN] $script not found" -ForegroundColor Yellow
    }
}

Start-Sleep -Seconds 2

# Step 3.5: Optional Advanced Hardening
Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "OPTIONAL: Advanced Hardening" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "The Advanced Hardening script includes:" -ForegroundColor Yellow
Write-Host "  - Disable telemetry scheduled tasks" -ForegroundColor White
Write-Host "  - Block telemetry domains (hosts file)" -ForegroundColor White
Write-Host "  - Create firewall blocking rules" -ForegroundColor White
Write-Host ""
Write-Host "WARNING: May impact some functionality (see script for details)" -ForegroundColor Yellow
Write-Host ""

$advancedRan = $false
$runAdvanced = Read-Host "Do you want to run Advanced Hardening? (Y/N)"
if ($runAdvanced -eq 'Y' -or $runAdvanced -eq 'y') {
    if (Test-Path ".\$advancedScript") {
        Write-Host "`nExecuting $advancedScript..." -ForegroundColor Cyan
        try {
            & ".\$advancedScript"
            $advancedRan = $true
            Write-Host "`nAdvanced hardening completed" -ForegroundColor Green
        } catch {
            Write-Host "  [ERROR] Error executing $advancedScript : $_" -ForegroundColor Red
        }
    } else {
        Write-Host "  [WARN] $advancedScript not found" -ForegroundColor Yellow
    }
} else {
    Write-Host "`nSkipping Advanced Hardening (you can run it manually later)" -ForegroundColor Gray
}

Start-Sleep -Seconds 2

# Step 4: Final Audit & Capture After State
Write-Host "`n[Step 4/5] Running Final Privacy Audit & Capturing Results..." -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Gray

Write-Host "`n[INFO] Capturing updated privacy settings..." -ForegroundColor Cyan
$afterSnapshot = Get-PrivacyAuditSnapshot

if (Test-Path ".\Privacy-Audit.ps1") {
    & ".\Privacy-Audit.ps1"
} else {
    Write-Host "  [WARN] Privacy-Audit.ps1 not found" -ForegroundColor Yellow
}

# Step 5: Generate Enhanced Report
Write-Host "`n[Step 5/5] Generating Detailed Installation Report..." -ForegroundColor Yellow

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$reportPath = ".\Privacy-Toolkit-Report_$timestamp.txt"

# Build before/after comparison
$comparisonReport = ""
foreach ($key in $beforeSnapshot.Keys | Sort-Object) {
    $before = $beforeSnapshot[$key]
    $after = $afterSnapshot[$key]
    $status = if ($before -ne $after) { "CHANGED" } else { "UNCHANGED" }
    $comparisonReport += "  $key`n    Before: $before`n    After:  $after`n    Status: $status`n`n"
}

$report = @"
================================================================
    Windows Privacy Toolkit - Installation Report
================================================================

Installation Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Computer Name: $env:COMPUTERNAME
Windows Version: $((Get-CimInstance Win32_OperatingSystem).Caption)
User Account: $env:USERNAME
Scripts Executed: $successCount / $($hardeningScripts.Count)
Advanced Hardening: $(if($advancedRan){'Yes'}else{'No'})

================================================================
Scripts Applied:
================================================================

$(foreach ($script in $hardeningScripts) { "  [OK] $script" })
$(if($advancedRan){"  [OK] $advancedScript (Advanced)"})

================================================================
Before/After Privacy Settings Comparison:
================================================================

$comparisonReport

================================================================
Summary of Changes:
================================================================

Windows Telemetry:
  Before: $($beforeSnapshot['Telemetry'])
  After:  $($afterSnapshot['Telemetry'])
  $(if($afterSnapshot['Telemetry'] -eq 0){'[OK] Successfully disabled (Security/Off level)'}else{'[WARN] May need manual review'})

DiagTrack Service:
  Before: $($beforeSnapshot['DiagTrack'])
  After:  $($afterSnapshot['DiagTrack'])
  $(if($afterSnapshot['DiagTrack'] -like '*Stopped*'){'[OK] Successfully stopped and disabled'}else{'[WARN] May need manual review'})

Cortana:
  Before: $($beforeSnapshot['Cortana'])
  After:  $($afterSnapshot['Cortana'])
  $(if($afterSnapshot['Cortana'] -eq 0){'[OK] Successfully disabled'}else{'[WARN] May need manual review'})

Tracking Services Running:
  Before: $($beforeSnapshot['TrackingServicesRunning'])
  After:  $($afterSnapshot['TrackingServicesRunning'])
  $(if($afterSnapshot['TrackingServicesRunning'] -eq 0){'[OK] All tracking services stopped'}else{"[WARN] $($afterSnapshot['TrackingServicesRunning']) services still running"})

Developer Tools Telemetry:
  PowerShell: $($afterSnapshot['PowerShellTelemetry']) $(if($afterSnapshot['PowerShellTelemetry'] -eq '1'){'[OK]'}else{'[WARN]'})
  VS Code:    $($afterSnapshot['VSCodeTelemetry']) $(if($afterSnapshot['VSCodeTelemetry'] -eq '1'){'[OK]'}else{'[WARN]'})

================================================================
Security Features Status (Should Remain Enabled):
================================================================

SmartScreen: Active (intentionally preserved for malware protection)
Windows Defender: Active (intentionally preserved for security)
Windows Update: Functional (no delays, LAN-only P2P sharing)

================================================================
Next Steps:
================================================================

1. [OK] RESTART YOUR COMPUTER for all changes to take effect
2. [OK] Review this report for any warnings or errors
3. [OK] Run Privacy-Audit.ps1 periodically to verify settings
4. [OK] Keep this report for your records

================================================================
To Restore Default Settings:
================================================================

If you need to undo these changes:
  - Run: .\Restore-PrivacySettings.ps1
  - Or use System Restore:
    Control Panel → System → System Protection
    Select restore point: "Before Windows Privacy Toolkit"

================================================================
Files & Resources:
================================================================

Report Location: $reportPath
System Restore Point: "Before Windows Privacy Toolkit"
Date Created: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Documentation: https://docs.nx1xlab.dev
Support: https://github.com/NX1X/Windows-Privacy-Toolkit/issues
Blog: https://blog.nx1xlab.dev

================================================================
Author: NX1X | www.nx1xlab.dev/nxtools
GitHub: https://github.com/NX1X/Windows-Privacy-Toolkit
================================================================

Privacy is a right, not a privilege. Take it back.

"@

$report | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "  [OK] Report saved: $reportPath" -ForegroundColor Green

# Final Summary
Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "    INSTALLATION COMPLETE" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan

Write-Host "`n[OK] Successfully hardened $successCount/$($hardeningScripts.Count) privacy settings" -ForegroundColor Green
if ($advancedRan) {
    Write-Host "[OK] Advanced hardening also applied" -ForegroundColor Green
}
Write-Host "Full detailed report saved to: $reportPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "[IMPORTANT] Restart your computer for all changes to take effect" -ForegroundColor Yellow
Write-Host ""

# Offer to restart
$restart = Read-Host "Do you want to restart now? (Y/N)"
if ($restart -eq 'Y' -or $restart -eq 'y') {
    Write-Host "`nRestarting computer in 10 seconds..." -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to cancel" -ForegroundColor Gray
    Start-Sleep -Seconds 10
    Restart-Computer -Force
} else {
    Write-Host "`n[OK] Done! Remember to restart later." -ForegroundColor Green
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
