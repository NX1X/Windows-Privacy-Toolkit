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
    "Install.ps1"                    = "11A44068098FEE0FC09BA26ED17AF4223CFE3F5E95486EA717BD9B4099865FC4"
    "Privacy-Audit.ps1"              = "6A9E8090A73A1A1FA8A8FA5328A348C5423714C4408F1E6F30976CC1BDF68419"
    "Disable-WindowsTelemetry.ps1"   = "10BDC1A5267234C31C32CDB9A68FD8A63A7C7B7860FBFC6B87C9CE5B9FA26224"
    "Disable-OfficeTelemetry.ps1"    = "5FED409A7EFF9C0241F52D7FDFA8048BA92F3DB1EAF03456B28002ADD422504D"
    "Disable-PowerShellTelemetry.ps1"= "CA42DDF8855BE55ED3C1BD45B353C755119406197E72375261AA20F5EE1C99A8"
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
