# Remove Microsoft 365 Bloatware Script
# Author: NX1X (www.nx1xlab.dev)
# Part of: NXTools (www.nx1xlab.dev/nxtools)
# License: MIT License
# Description: Removes pre-installed Microsoft 365 (Office) bloatware from Windows 11
#
# ⚠️ DISCLAIMER: USE AT YOUR OWN RISK
# - This script removes Microsoft 365 apps (pre-installed bloatware)
# - Does NOT remove user-installed full Office applications
# - Only removes AppX packages (web apps/stubs)
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

Clear-Host

Write-Host "`n=== REMOVE MICROSOFT 365 BLOATWARE ===" -ForegroundColor Cyan
Write-Host "Author: NX1X | www.nx1xlab.dev/nxtools`n" -ForegroundColor Gray

Write-Host "⚠️  WARNING: OFFICE BLOATWARE REMOVAL" -ForegroundColor Yellow
Write-Host "=======================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "This script will remove:" -ForegroundColor Yellow
Write-Host "  - Microsoft 365 (Office) web apps/stubs" -ForegroundColor White
Write-Host "  - OneDrive (pre-installed)" -ForegroundColor White
Write-Host "  - Microsoft Teams (consumer version)" -ForegroundColor White
Write-Host "  - Other pre-installed Office AppX packages" -ForegroundColor White
Write-Host ""
Write-Host "NOTE: This will NOT remove:" -ForegroundColor Green
Write-Host "  - User-installed Microsoft Office (desktop apps)" -ForegroundColor Gray
Write-Host "  - Microsoft 365 subscriptions you purchased" -ForegroundColor Gray
Write-Host "  - OneDrive files (files are safe, only the app is removed)" -ForegroundColor Gray
Write-Host ""

$confirm = Read-Host "Do you want to remove Microsoft 365 bloatware? (Y/N)"

if ($confirm -ne 'Y' -and $confirm -ne 'y') {
    Write-Host "`nCancelled by user. No changes made." -ForegroundColor Red
    exit 0
}

Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "Starting Microsoft 365 Bloatware Removal..." -ForegroundColor Cyan
Write-Host "================================================================`n" -ForegroundColor Cyan

$removedCount = 0

# List of Microsoft 365/Office bloatware AppX packages to remove
$bloatwarePackages = @(
    "Microsoft.Office.Desktop",
    "Microsoft.Office.Desktop.Access",
    "Microsoft.Office.Desktop.Excel",
    "Microsoft.Office.Desktop.Outlook",
    "Microsoft.Office.Desktop.PowerPoint",
    "Microsoft.Office.Desktop.Publisher",
    "Microsoft.Office.Desktop.Word",
    "Microsoft.Office.OneNote",
    "Microsoft.Office.Sway",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.OutlookForWindows",
    "Microsoft.OneDrive",
    "Microsoft.OneDriveSync",
    "Microsoft.Teams",
    "MicrosoftTeams",
    "Microsoft.Todos"
)

Write-Host "[1/3] Removing Microsoft 365 AppX Packages..." -ForegroundColor Yellow

foreach ($package in $bloatwarePackages) {
    try {
        # Check if package exists for current user
        $appxPackage = Get-AppxPackage -Name $package -ErrorAction SilentlyContinue

        if ($appxPackage) {
            Write-Host "  [INFO] Removing: $package" -ForegroundColor Cyan
            Remove-AppxPackage -Package $appxPackage.PackageFullName -ErrorAction Stop | Out-Null
            Write-Host "  [OK] Removed: $package" -ForegroundColor Green
            $removedCount++
        }

        # Also remove provisioned packages (prevents reinstall for new users)
        $provisionedPackage = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $package } -ErrorAction SilentlyContinue

        if ($provisionedPackage) {
            Write-Host "  [INFO] Removing provisioned package: $package" -ForegroundColor Cyan
            Remove-AppxProvisionedPackage -Online -PackageName $provisionedPackage.PackageName -ErrorAction Stop | Out-Null
            Write-Host "  [OK] Removed provisioned: $package" -ForegroundColor Green
        }

    } catch {
        # Package not found or already removed, skip silently
    }
}

Write-Host "  [OK] Removed $removedCount Microsoft 365 packages" -ForegroundColor Green

# Disable OneDrive startup (if registry keys exist)
Write-Host "`n[2/3] Disabling OneDrive Startup..." -ForegroundColor Yellow
try {
    # Disable OneDrive from starting automatically
    if (Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run") {
        Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive" -ErrorAction SilentlyContinue
        Write-Host "  [OK] OneDrive startup disabled" -ForegroundColor Green
    }

    # Remove OneDrive from Explorer sidebar
    if (!(Test-Path "HKCR:")) { New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null }
    Set-ItemProperty -Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Name "System.IsPinnedToNameSpaceTree" -Value 0 -ErrorAction SilentlyContinue
    Write-Host "  [OK] OneDrive removed from Explorer sidebar" -ForegroundColor Green

} catch {
    Write-Host "  [INFO] OneDrive startup settings not found" -ForegroundColor Gray
}

# Disable Microsoft Teams auto-start
Write-Host "`n[3/3] Disabling Teams Auto-Start..." -ForegroundColor Yellow
try {
    # Disable Teams from starting automatically
    if (Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run") {
        Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "com.squirrel.Teams.Teams" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "MicrosoftTeams" -ErrorAction SilentlyContinue
        Write-Host "  [OK] Teams auto-start disabled" -ForegroundColor Green
    }
} catch {
    Write-Host "  [INFO] Teams startup settings not found" -ForegroundColor Gray
}

Write-Host "`n=== BLOATWARE REMOVAL COMPLETE ===" -ForegroundColor Green
Write-Host ""
Write-Host "[OK] Successfully removed Microsoft 365 bloatware!" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  - Removed $removedCount AppX packages" -ForegroundColor White
Write-Host "  - Disabled OneDrive startup" -ForegroundColor White
Write-Host "  - Disabled Teams auto-start" -ForegroundColor White
Write-Host ""
Write-Host "IMPORTANT NOTES:" -ForegroundColor Yellow
Write-Host "  - A restart is recommended for all changes to take effect" -ForegroundColor White
Write-Host "  - Your OneDrive files are safe (only the app was removed)" -ForegroundColor White
Write-Host "  - You can reinstall from Microsoft Store if needed" -ForegroundColor White
Write-Host "  - User-installed Office (desktop) was NOT affected" -ForegroundColor White
Write-Host ""

Write-Host "More info: https://github.com/NX1X/Windows-Privacy-Toolkit" -ForegroundColor Gray
Write-Host "Docs: https://docs.nx1xlab.dev | Blog: https://blog.nx1xlab.dev`n" -ForegroundColor Gray

Read-Host "Press Enter to exit"
