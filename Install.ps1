# Windows Privacy Toolkit - One-Click Installer
# Author: NX1X (www.nx1xlab.dev)
# Part of: NXTools (www.nx1xlab.dev/nxtools)
# License: MIT License
# Description: Automated installer that runs all privacy hardening scripts
#
# ⚠️ DISCLAIMER: USE AT YOUR OWN RISK
# - Tested on Windows 11 (24H2)
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
        Start-Process PowerShell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"Set-Location -LiteralPath '$((Get-Item $scriptPath).DirectoryName)'; & '$scriptPath'`""
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
Write-Host "  5. Generate a detailed report" -ForegroundColor White
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

# Step 2: Initial Audit
Write-Host "`n[Step 2/5] Running Initial Privacy Audit..." -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Gray

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

# Step 4: Final Audit
Write-Host "`n[Step 4/5] Running Final Privacy Audit..." -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Gray

if (Test-Path ".\Privacy-Audit.ps1") {
    & ".\Privacy-Audit.ps1"
} else {
    Write-Host "  [WARN] Privacy-Audit.ps1 not found" -ForegroundColor Yellow
}

# Step 5: Generate Report
Write-Host "`n[Step 5/5] Generating Installation Report..." -ForegroundColor Yellow

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$reportPath = ".\Privacy-Toolkit-Report_$timestamp.txt"

$report = @"
================================================================
    Windows Privacy Toolkit - Installation Report
================================================================

Installation Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Computer Name: $env:COMPUTERNAME
Windows Version: $((Get-CimInstance Win32_OperatingSystem).Caption)
Scripts Executed: $successCount / $($hardeningScripts.Count)

Scripts Applied:
$(foreach ($script in $hardeningScripts) { "  - $script" })

================================================================
Next Steps:
================================================================

1. RESTART YOUR COMPUTER for all changes to take effect
2. Review this report for any warnings or errors
3. Run Privacy-Audit.ps1 periodically to verify settings

To restore your system if needed:
  - Go to: Control Panel → System → System Protection
  - Click "System Restore" and select the restore point:
    "Before Windows Privacy Toolkit"

================================================================
Author: NX1X | www.nx1xlab.dev/nxtools
GitHub: https://github.com/NX1X/Windows-Privacy-Toolkit
Docs: https://docs.nx1xlab.dev | Blog: https://blog.nx1xlab.dev
================================================================
"@

$report | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "  [OK] Report saved: $reportPath" -ForegroundColor Green

# Final Summary
Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "    INSTALLATION COMPLETE" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan

Write-Host "`n[OK] Successfully hardened $successCount/$($hardeningScripts.Count) privacy settings" -ForegroundColor Green
Write-Host "Full report saved to: $reportPath" -ForegroundColor Cyan
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
