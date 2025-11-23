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
        Invoke-WebRequest -Uri $url -OutFile $outPath -UseBasicParsing
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

Write-Host "`n[OK] All scripts downloaded successfully!" -ForegroundColor Green
Write-Host "`nStarting installation..." -ForegroundColor Yellow

# Change to install directory and run Install.ps1
Set-Location $installDir
& "$installDir\Install.ps1"
