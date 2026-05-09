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
    "Install.ps1"                    = "CD3C7403673BF8629D0AAD871C5AED366750AB7C940C550E19FB81E9236560B4"
    "Privacy-Audit.ps1"              = "CDD92557B7C5E2C1A8AC405AB1928D18F1A1904E7CB0B0715315A9CAF83E249F"
    "Disable-WindowsTelemetry.ps1"   = "CB3571F269004D75D256BE27E2D019ECA54DC1A3750B5F8190D4A06FED00736D"
    "Disable-OfficeTelemetry.ps1"    = "020DB7001AD01C141DACDEF8976AC283F3C5B839EFE0EC425CD145E90E9AF49B"
    "Disable-PowerShellTelemetry.ps1"= "11FBCA67132EF9CFE1E39E442E0D6780AF7333F5D00400CBDF7E8BDAD80C4375"
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
