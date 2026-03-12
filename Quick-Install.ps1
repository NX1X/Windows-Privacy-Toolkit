# Windows Privacy Toolkit - Quick Installer
# Author: NX1X (www.nx1xlab.dev)
# Repository: https://github.com/NX1X/Windows-Privacy-Toolkit
#
# This script downloads and runs the Windows Privacy Toolkit
# Run with: iwr "https://raw.githubusercontent.com/NX1X/Windows-Privacy-Toolkit/main/Quick-Install.ps1" | iex

# Self-elevate if not admin
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Write-Host "Requesting administrator privileges..." -ForegroundColor Yellow
    $scriptUrl = "https://raw.githubusercontent.com/NX1X/Windows-Privacy-Toolkit/main/Quick-Install.ps1"
    Start-Process PowerShell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"iwr '$scriptUrl' | iex`""
    exit
}

# Enforce TLS 1.2 for all web requests
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Set encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host @"

+==============================================================+
|                                                              |
|        Windows Privacy Toolkit - Quick Installer             |
|                                                              |
|                    Author: NX1X                              |
|              www.nx1xlab.dev/nxtools                         |
|                                                              |
+==============================================================+

"@ -ForegroundColor Cyan

# Configuration
$repoBase = "https://raw.githubusercontent.com/NX1X/Windows-Privacy-Toolkit/main"
$installDir = "$env:USERPROFILE\Windows-Privacy-Toolkit"

# Scripts to download
$scripts = @(
    "Install.ps1",
    "Privacy-Audit.ps1",
    "Disable-WindowsTelemetry.ps1",
    "Disable-OfficeTelemetry.ps1",
    "Disable-PowerShellTelemetry.ps1"
)

Write-Host "Downloading Windows Privacy Toolkit..." -ForegroundColor Yellow
Write-Host "Install directory: $installDir" -ForegroundColor Gray

# Create directory
if (!(Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
}

# Download all scripts
$downloadSuccess = $true
foreach ($script in $scripts) {
    Write-Host "  Downloading $script..." -ForegroundColor Gray
    try {
        $url = "$repoBase/$script"
        $outPath = "$installDir\$script"
        Invoke-WebRequest -Uri $url -OutFile $outPath -UseBasicParsing -SslProtocol Tls12
        Write-Host "    [OK]" -ForegroundColor Green
    } catch {
        Write-Host "    [FAILED] $_" -ForegroundColor Red
        $downloadSuccess = $false
    }
}

if (-not $downloadSuccess) {
    Write-Host "`n[ERROR] Some downloads failed. Please check your internet connection." -ForegroundColor Red
    Write-Host "You can manually download from: https://github.com/NX1X/Windows-Privacy-Toolkit" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# SHA256 integrity verification
# !!MAINTAINER: After any script change, regenerate these hashes by running:
#   Get-FileHash Install.ps1,Privacy-Audit.ps1,Disable-WindowsTelemetry.ps1,Disable-OfficeTelemetry.ps1,Disable-PowerShellTelemetry.ps1 -Algorithm SHA256 | Select Hash,Path
# Then replace the values below with the new output (uppercase hex).
$expectedHashes = @{
    "Install.ps1"                    = "521A3E6E80778718CB02F14857B433DF248CF6C9341F3E5EF348E4D63A498158"
    "Privacy-Audit.ps1"              = "1D48BDF2358AE52901AE3B3935C0E2F2A02F36BC20C4678301A8256F10E9FC64"
    "Disable-WindowsTelemetry.ps1"   = "E4F1A0CF6BDF19BFDF2F8665F8CCB49C981BA7E6974813EAE3B4740FC4D3CB89"
    "Disable-OfficeTelemetry.ps1"    = "3D07885E2B0361AF8FC71689E3CB79914FD72E42FAFC22CAF3479C0338E494A4"
    "Disable-PowerShellTelemetry.ps1"= "835AEDD647A6C578A13142C9192F20AED87651DB877203AB92C5F1B26B340E92"
}

Write-Host "`nVerifying script integrity..." -ForegroundColor Yellow
$hashOk = $true
foreach ($script in $scripts) {
    $outPath = "$installDir\$script"
    $actual = (Get-FileHash -Path $outPath -Algorithm SHA256).Hash
    $expected = $expectedHashes[$script]
    if ($expected -ne "REPLACE_WITH_HASH" -and $actual -ne $expected) {
        Write-Host "  [FAILED] Hash mismatch: $script" -ForegroundColor Red
        Write-Host "    Expected: $expected" -ForegroundColor Gray
        Write-Host "    Got:      $actual" -ForegroundColor Gray
        $hashOk = $false
    } else {
        Write-Host "  [OK] $script" -ForegroundColor Green
    }
}

if (-not $hashOk) {
    Write-Host "`n[ERROR] Integrity check failed. Aborting for your safety." -ForegroundColor Red
    Write-Host "The downloaded files may have been tampered with." -ForegroundColor Yellow
    Remove-Item "$installDir\*" -Force -ErrorAction SilentlyContinue
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "`n[OK] All scripts downloaded and verified!" -ForegroundColor Green
Write-Host "`nStarting installation..." -ForegroundColor Yellow

# Change to install directory and run Install.ps1
Set-Location $installDir
& "$installDir\Install.ps1"
