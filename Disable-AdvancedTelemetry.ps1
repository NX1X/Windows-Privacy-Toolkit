# Advanced Telemetry Hardening Script (OPTIONAL)
# Author: NX1X (www.nx1xlab.dev)
# Part of: NXTools (www.nx1xlab.dev/nxtools)
# License: MIT License
# Description: Advanced privacy hardening with scheduled tasks, hosts file, and firewall blocking
#
# ⚠️ DISCLAIMER: USE AT YOUR OWN RISK
# - This is an OPTIONAL advanced script
# - May impact some Windows functionality
# - Hosts file blocking may slow Windows Update checks by 30-60 seconds
# - May break Windows built-in troubleshooters
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

Write-Host "`n=== ADVANCED PRIVACY HARDENING (OPTIONAL) ===" -ForegroundColor Cyan
Write-Host "Author: NX1X | www.nx1xlab.dev/nxtools`n" -ForegroundColor Gray

Write-Host "⚠️  WARNING: ADVANCED HARDENING OPTIONS" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "[!] This script includes advanced hardening that MAY impact functionality:" -ForegroundColor Yellow
Write-Host ""
Write-Host "    OPTION 1: Disable Telemetry Scheduled Tasks (SAFEST)" -ForegroundColor White
Write-Host "      - Disables 15+ Microsoft telemetry scheduled tasks" -ForegroundColor Gray
Write-Host "      - Generally safe, minimal impact" -ForegroundColor Gray
Write-Host "      - May affect Windows diagnostics features" -ForegroundColor Gray
Write-Host ""
Write-Host "    OPTION 2: Block Telemetry via Hosts File (MODERATE IMPACT)" -ForegroundColor White
Write-Host "      - Blocks 35+ telemetry domains in hosts file" -ForegroundColor Gray
Write-Host "      - Windows Update checks may be 30-60 seconds slower" -ForegroundColor Gray
Write-Host "      - Built-in troubleshooters may not work" -ForegroundColor Gray
Write-Host "      - Store downloads may be slightly slower" -ForegroundColor Gray
Write-Host ""
Write-Host "    OPTION 3: Create Firewall Rules (SIMILAR TO HOSTS FILE)" -ForegroundColor White
Write-Host "      - Creates outbound firewall blocking rules" -ForegroundColor Gray
Write-Host "      - Similar impact to hosts file blocking" -ForegroundColor Gray
Write-Host "      - More comprehensive blocking" -ForegroundColor Gray
Write-Host ""

Write-Host "Choose your hardening level:" -ForegroundColor Cyan
Write-Host "  [1] Tasks only (safest, minimal impact)" -ForegroundColor Green
Write-Host "  [2] Tasks + Hosts file (moderate impact)" -ForegroundColor Yellow
Write-Host "  [3] Tasks + Hosts + Firewall (maximum hardening, more impact)" -ForegroundColor Yellow
Write-Host "  [0] Cancel and exit" -ForegroundColor Red
Write-Host ""

$choice = Read-Host "Enter your choice (0-3)"

if ($choice -eq '0') {
    Write-Host "`nCancelled by user. No changes made." -ForegroundColor Red
    exit 0
}

if ($choice -notin @('1', '2', '3')) {
    Write-Host "`nInvalid choice. Exiting." -ForegroundColor Red
    exit 1
}

Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "Starting Advanced Hardening (Level $choice)..." -ForegroundColor Cyan
Write-Host "================================================================`n" -ForegroundColor Cyan

# ============================================================================
# STEP 1: Disable Telemetry Scheduled Tasks (ALL OPTIONS)
# ============================================================================

Write-Host "[1/3] Disabling Telemetry Scheduled Tasks..." -ForegroundColor Yellow

$tasksToDisable = @(
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

$disabledTaskCount = 0
foreach ($task in $tasksToDisable) {
    try {
        $scheduledTask = Get-ScheduledTask -TaskPath (Split-Path $task -Parent) -TaskName (Split-Path $task -Leaf) -ErrorAction SilentlyContinue
        if ($scheduledTask) {
            Disable-ScheduledTask -TaskPath (Split-Path $task -Parent) -TaskName (Split-Path $task -Leaf) -ErrorAction SilentlyContinue | Out-Null
            $disabledTaskCount++
        }
    } catch {
        # Task doesn't exist, skip
    }
}

Write-Host "  [OK] Disabled $disabledTaskCount telemetry scheduled tasks" -ForegroundColor Green

# ============================================================================
# STEP 2: Hosts File Blocking (OPTIONS 2 & 3)
# ============================================================================

if ($choice -in @('2', '3')) {
    Write-Host "`n[2/3] Blocking Telemetry Domains in Hosts File..." -ForegroundColor Yellow

    $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
    $telemetryDomains = @(
        "vortex.data.microsoft.com",
        "vortex-win.data.microsoft.com",
        "telecommand.telemetry.microsoft.com",
        "oca.telemetry.microsoft.com",
        "sqm.telemetry.microsoft.com",
        "watson.telemetry.microsoft.com",
        "redir.metaservices.microsoft.com",
        "choice.microsoft.com",
        "df.telemetry.microsoft.com",
        "reports.wes.df.telemetry.microsoft.com",
        "wes.df.telemetry.microsoft.com",
        "services.wes.df.telemetry.microsoft.com",
        "sqm.df.telemetry.microsoft.com",
        "telemetry.microsoft.com",
        "watson.ppe.telemetry.microsoft.com",
        "telemetry.appex.bing.net",
        "telemetry.urs.microsoft.com",
        "settings-sandbox.data.microsoft.com",
        "vortex-sandbox.data.microsoft.com",
        "survey.watson.microsoft.com",
        "watson.live.com",
        "statsfe2.ws.microsoft.com",
        "corpext.msitadfs.glbdns2.microsoft.com",
        "compatexchange.cloudapp.net",
        "cs1.wpc.v0cdn.net",
        "a-0001.a-msedge.net",
        "statsfe2.update.microsoft.com.akadns.net",
        "sls.update.microsoft.com.akadns.net",
        "fe2.update.microsoft.com.akadns.net",
        "diagnostics.support.microsoft.com",
        "corp.sts.microsoft.com",
        "statsfe1.ws.microsoft.com",
        "feedback.windows.com",
        "feedback.microsoft-hohm.com",
        "feedback.search.microsoft.com"
    )

    # Backup hosts file
    try {
        Copy-Item -Path $hostsPath -Destination "$hostsPath.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')" -Force
        Write-Host "  [OK] Hosts file backed up" -ForegroundColor Green
    } catch {
        Write-Host "  [WARN] Could not backup hosts file" -ForegroundColor Yellow
    }

    # Read current hosts file
    $hostsContent = Get-Content -Path $hostsPath -ErrorAction SilentlyContinue
    if (-not $hostsContent) { $hostsContent = @() }

    # Build list of entries to add
    $entriesToAdd = @()
    $marker = "# Windows Privacy Toolkit - Telemetry Blocking"

    if ($hostsContent -notcontains $marker) {
        $entriesToAdd += ""
        $entriesToAdd += $marker
    }

    # Check and add domains
    $addedCount = 0
    foreach ($domain in $telemetryDomains) {
        $entry = "127.0.0.1 $domain"
        if ($hostsContent -notcontains $entry) {
            $entriesToAdd += $entry
            $addedCount++
        }
    }

    # Write all entries at once if there are any to add
    if ($entriesToAdd.Count -gt 0) {
        try {
            # Append all new entries in one operation
            $entriesToAdd | Out-File -FilePath $hostsPath -Append -Encoding ASCII -Force
        } catch {
            Write-Host "  [WARN] Could not write to hosts file: $_" -ForegroundColor Yellow
        }
    }

    Write-Host "  [OK] Blocked $addedCount telemetry domains in hosts file" -ForegroundColor Green
    Write-Host "  [INFO] Hosts file backed up to: $hostsPath.backup_*" -ForegroundColor Gray

    # Flush DNS cache
    try {
        ipconfig /flushdns | Out-Null
        Write-Host "  [OK] DNS cache flushed" -ForegroundColor Green
    } catch {
        Write-Host "  [WARN] Could not flush DNS cache" -ForegroundColor Yellow
    }
} else {
    Write-Host "`n[2/3] Skipping Hosts File Blocking (not selected)" -ForegroundColor Gray
}

# ============================================================================
# STEP 3: Firewall Rules (OPTION 3 ONLY)
# ============================================================================

if ($choice -eq '3') {
    Write-Host "`n[3/3] Creating Firewall Rules to Block Telemetry..." -ForegroundColor Yellow

    $firewallRuleName = "Windows Privacy Toolkit - Block Telemetry"

    # Remove existing rule if present
    try {
        Remove-NetFirewallRule -DisplayName $firewallRuleName -ErrorAction SilentlyContinue
    } catch {
        # Rule doesn't exist
    }

    # Create new outbound blocking rules for telemetry
    # Note: Firewall rules require IP addresses, not domain names
    # We'll create rules for known Microsoft telemetry IP ranges

    $telemetryIPs = @(
        "65.52.0.0/14",          # Microsoft Azure range (telemetry servers)
        "134.170.0.0/16",        # Microsoft range
        "207.46.0.0/16"          # Microsoft range
    )

    $ruleCreated = $false
    foreach ($ip in $telemetryIPs) {
        try {
            $ruleName = "$firewallRuleName - $ip"
            Remove-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue | Out-Null

            New-NetFirewallRule -DisplayName $ruleName `
                -Direction Outbound `
                -Action Block `
                -RemoteAddress $ip `
                -Description "Blocks telemetry endpoints (Windows Privacy Toolkit)" `
                -Enabled True | Out-Null

            $ruleCreated = $true
        } catch {
            # Continue with next IP range
        }
    }

    if ($ruleCreated) {
        Write-Host "  [OK] Firewall rules created to block telemetry IP ranges" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] Could not create firewall rules" -ForegroundColor Yellow
    }
} else {
    Write-Host "`n[3/3] Skipping Firewall Rules (not selected)" -ForegroundColor Gray
}

# ============================================================================
# Summary
# ============================================================================

Write-Host "`n=== ADVANCED HARDENING COMPLETE ===" -ForegroundColor Cyan

Write-Host "`n[OK] Advanced hardening applied successfully (Level $choice)!" -ForegroundColor Green

Write-Host "`nWhat was applied:" -ForegroundColor Cyan
Write-Host "  - Disabled $disabledTaskCount telemetry scheduled tasks" -ForegroundColor White
if ($choice -in @('2', '3')) {
    Write-Host "  - Blocked telemetry domains in hosts file" -ForegroundColor White
}
if ($choice -eq '3') {
    Write-Host "  - Created firewall rules to block telemetry" -ForegroundColor White
}

Write-Host "`nIMPORTANT NOTES:" -ForegroundColor Yellow
if ($choice -in @('2', '3')) {
    Write-Host "  - Windows Update checks may be 30-60 seconds slower" -ForegroundColor Gray
    Write-Host "  - Built-in troubleshooters may not work" -ForegroundColor Gray
    Write-Host "  - To restore: Edit $hostsPath and remove marked entries" -ForegroundColor Gray
}
Write-Host "  - Run Privacy-Audit.ps1 to verify changes" -ForegroundColor Gray
Write-Host "  - A restart is recommended for all changes to take effect" -ForegroundColor Gray

Write-Host "`nMore info: https://github.com/NX1X/Windows-Privacy-Toolkit" -ForegroundColor DarkGray
Write-Host "Docs: https://docs.nx1xlab.dev | Blog: https://blog.nx1xlab.dev`n" -ForegroundColor DarkGray

# Keep window open if run via context menu
if ($Host.Name -eq 'ConsoleHost') {
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
