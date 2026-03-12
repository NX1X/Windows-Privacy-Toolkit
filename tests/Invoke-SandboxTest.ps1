# Windows Privacy Toolkit - Sandbox Functional Test
# Runs automatically when launched via Test-InSandbox.wsb
# Tests the actual scripts against real Windows settings in an isolated environment.

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$pass = 0
$fail = 0

function Write-Pass($msg) { Write-Host "  [PASS] $msg" -ForegroundColor Green;  $script:pass++ }
function Write-Fail($msg) { Write-Host "  [FAIL] $msg" -ForegroundColor Red;    $script:fail++ }
function Write-Section($title) {
    Write-Host "`n================================================================" -ForegroundColor Cyan
    Write-Host "  $title" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
}

# ── Setup: copy read-only mount to writable working dir ─────────────────────

$workDir = "C:\TestKit"
Write-Host "Copying toolkit to $workDir..." -ForegroundColor Yellow
Copy-Item -Path "C:\TestKit-ReadOnly\*" -Destination $workDir -Recurse -Force
Set-Location $workDir

# ── Helper: read a registry value safely ────────────────────────────────────

function Get-RegValue($path, $name) {
    try { return (Get-ItemProperty -Path $path -Name $name -ErrorAction Stop).$name }
    catch { return $null }
}

function Get-ServiceStartType($name) {
    $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
    if ($svc) { return (Get-WmiObject Win32_Service -Filter "Name='$name'").StartMode }
    return $null
}

# ── Capture baseline ─────────────────────────────────────────────────────────

Write-Section "Baseline (before)"
$baseline = @{
    Telemetry     = Get-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry"
    AdvertisingID = Get-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled"
    Cortana       = Get-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana"
    DiagTrack     = (Get-Service DiagTrack -ErrorAction SilentlyContinue)?.Status
}
$baseline.GetEnumerator() | ForEach-Object {
    Write-Host "  $($_.Key): $($_.Value ?? '(not set)')" -ForegroundColor Gray
}

# ── Run Privacy-Audit.ps1 (read-only — should never fail) ───────────────────

Write-Section "Privacy-Audit.ps1"
try {
    & "$workDir\Privacy-Audit.ps1"
    Write-Pass "Privacy-Audit.ps1 completed without errors"
} catch {
    Write-Fail "Privacy-Audit.ps1 threw an exception: $_"
}

# ── Run Disable-WindowsTelemetry.ps1 ────────────────────────────────────────

Write-Section "Disable-WindowsTelemetry.ps1"
try {
    & "$workDir\Disable-WindowsTelemetry.ps1"
    Write-Pass "Disable-WindowsTelemetry.ps1 ran without errors"
} catch {
    Write-Fail "Disable-WindowsTelemetry.ps1 threw: $_"
}

# Verify key registry values were actually set
$telemetry = Get-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry"
if ($telemetry -eq 0) { Write-Pass "AllowTelemetry = 0 (disabled)" }
else                   { Write-Fail "AllowTelemetry = $telemetry (expected 0)" }

$adId = Get-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled"
if ($adId -eq 0) { Write-Pass "AdvertisingInfo.Enabled = 0 (disabled)" }
else              { Write-Fail "AdvertisingInfo.Enabled = $adId (expected 0)" }

$cortana = Get-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana"
if ($cortana -eq 0) { Write-Pass "AllowCortana = 0 (disabled)" }
else                 { Write-Fail "AllowCortana = $cortana (expected 0)" }

$diagTrack = Get-Service DiagTrack -ErrorAction SilentlyContinue
if ($diagTrack -and $diagTrack.Status -eq 'Stopped') { Write-Pass "DiagTrack service stopped" }
elseif (!$diagTrack)                                  { Write-Pass "DiagTrack service not present" }
else                                                   { Write-Fail "DiagTrack still running: $($diagTrack.Status)" }

# ── Run Disable-OfficeTelemetry.ps1 ─────────────────────────────────────────

Write-Section "Disable-OfficeTelemetry.ps1"
try {
    & "$workDir\Disable-OfficeTelemetry.ps1"
    Write-Pass "Disable-OfficeTelemetry.ps1 ran without errors"
} catch {
    Write-Fail "Disable-OfficeTelemetry.ps1 threw: $_"
}

$officeCeip = Get-RegValue "HKCU:\Software\Policies\Microsoft\office\16.0\common" "QMEnable"
if ($officeCeip -eq 0) { Write-Pass "Office CEIP disabled (QMEnable = 0)" }
else                    { Write-Fail "Office CEIP not disabled (QMEnable = $officeCeip)" }

# ── Run Disable-PowerShellTelemetry.ps1 ─────────────────────────────────────

Write-Section "Disable-PowerShellTelemetry.ps1"
try {
    & "$workDir\Disable-PowerShellTelemetry.ps1"
    Write-Pass "Disable-PowerShellTelemetry.ps1 ran without errors"
} catch {
    Write-Fail "Disable-PowerShellTelemetry.ps1 threw: $_"
}

$psOptOut = [System.Environment]::GetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', 'Machine')
if ($psOptOut -eq '1') { Write-Pass "POWERSHELL_TELEMETRY_OPTOUT = 1" }
else                    { Write-Fail "POWERSHELL_TELEMETRY_OPTOUT = '$psOptOut' (expected '1')" }

# ── Run Privacy-Audit.ps1 again (after) — should show changes ───────────────

Write-Section "Privacy-Audit.ps1 (after hardening)"
try {
    & "$workDir\Privacy-Audit.ps1"
    Write-Pass "Post-hardening audit completed"
} catch {
    Write-Fail "Post-hardening audit threw: $_"
}

# ── Summary ──────────────────────────────────────────────────────────────────

Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "  SANDBOX TEST RESULTS" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Passed: $pass" -ForegroundColor Green
Write-Host "  Failed: $fail" -ForegroundColor $(if ($fail -gt 0) { 'Red' } else { 'Green' })
Write-Host "================================================================`n" -ForegroundColor Cyan

if ($fail -gt 0) {
    Write-Host "[BLOCKED] $fail test(s) failed. Do not release." -ForegroundColor Red
} else {
    Write-Host "[OK] All functional tests passed. Safe to push." -ForegroundColor Green
}

Write-Host "`nThis window will close in 60 seconds (or press any key)..." -ForegroundColor Gray
$null = Start-Sleep -Seconds 1
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
