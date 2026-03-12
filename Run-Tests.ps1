# Windows Privacy Toolkit - Local Test Runner
# Mirrors the GitHub Actions test.yml workflow so you can validate before pushing.
# Run from the repo root: .\Run-Tests.ps1

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$pass = 0
$fail = 0
$warn = 0

function Write-Pass($msg) { Write-Host "  [PASS] $msg" -ForegroundColor Green;  $script:pass++ }
function Write-Fail($msg) { Write-Host "  [FAIL] $msg" -ForegroundColor Red;    $script:fail++ }
function Write-Warn($msg) { Write-Host "  [WARN] $msg" -ForegroundColor Yellow; $script:warn++ }
function Write-Section($title) {
    Write-Host "`n================================================================" -ForegroundColor Cyan
    Write-Host "  $title" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
}

# ── 1. Required files ────────────────────────────────────────────────────────

Write-Section "1/5  Required Files"

$required = @(
    "Install.ps1",
    "Privacy-Audit.ps1",
    "Disable-WindowsTelemetry.ps1",
    "Disable-OfficeTelemetry.ps1",
    "Disable-PowerShellTelemetry.ps1",
    "Quick-Install.ps1",
    "README.md",
    "CHANGELOG.md"
)

foreach ($file in $required) {
    if (Test-Path $file) { Write-Pass "$file exists" }
    else                 { Write-Fail "$file is MISSING" }
}

# ── 2. Syntax validation ─────────────────────────────────────────────────────

Write-Section "2/5  Syntax Validation"

$scripts = Get-ChildItem -Path . -Filter "*.ps1"
foreach ($script in $scripts) {
    try {
        $errors = $null
        $null = [System.Management.Automation.PSParser]::Tokenize(
            (Get-Content $script.FullName -Raw), [ref]$errors
        )
        if ($errors.Count -gt 0) {
            Write-Fail "$($script.Name) — $($errors.Count) parse error(s)"
            $errors | ForEach-Object { Write-Host "    Line $($_.Token.StartLine): $($_.Message)" -ForegroundColor Gray }
        } else {
            Write-Pass "$($script.Name)"
        }
    } catch {
        Write-Fail "$($script.Name) — $_"
    }
}

# ── 3. PSScriptAnalyzer ──────────────────────────────────────────────────────

Write-Section "3/5  PSScriptAnalyzer"

if (!(Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    Write-Host "  Installing PSScriptAnalyzer..." -ForegroundColor Yellow
    Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
}
Import-Module PSScriptAnalyzer -ErrorAction Stop

$securityRules = @(
    'PSAvoidUsingPlainTextForPassword',
    'PSAvoidUsingConvertToSecureStringWithPlainText',
    'PSAvoidUsingUsernameAndPasswordParams',
    'PSAvoidUsingInvokeExpression'
)

$totalIssues = 0
foreach ($script in $scripts) {
    $results = Invoke-ScriptAnalyzer -Path $script.FullName -Severity Error, Warning -IncludeRule $securityRules
    if ($results) {
        foreach ($r in $results) {
            Write-Fail "$($script.Name):$($r.Line) [$($r.Severity)] $($r.RuleName)"
            Write-Host "    $($r.Message)" -ForegroundColor Gray
        }
        $totalIssues += $results.Count
    } else {
        Write-Pass "$($script.Name) — no security issues"
    }
}

# General lint (errors only block, warnings are informational)
$lintErrors = Invoke-ScriptAnalyzer -Path . -Recurse -Severity Error
if ($lintErrors) {
    foreach ($e in $lintErrors) {
        Write-Fail "$($e.ScriptName):$($e.Line) $($e.RuleName)"
    }
} else {
    Write-Pass "No PSScriptAnalyzer errors"
}

# ── 4. Safety checks ─────────────────────────────────────────────────────────

Write-Section "4/5  Safety Checks"

# Admin elevation present in all main scripts
$elevationScripts = @(
    "Install.ps1",
    "Privacy-Audit.ps1",
    "Disable-WindowsTelemetry.ps1",
    "Disable-OfficeTelemetry.ps1",
    "Disable-PowerShellTelemetry.ps1"
)
foreach ($s in $elevationScripts) {
    if (!(Test-Path $s)) { continue }
    $content = Get-Content $s -Raw
    if ($content -match "IsInRole.*Administrator") {
        Write-Pass "$s has admin elevation"
    } else {
        Write-Warn "$s is missing admin elevation check"
    }
}

# Install.ps1 has a restore point
$installContent = Get-Content "Install.ps1" -Raw -ErrorAction SilentlyContinue
if ($installContent -match "Checkpoint-Computer") {
    Write-Pass "Install.ps1 creates a system restore point"
} else {
    Write-Warn "Install.ps1 may be missing Checkpoint-Computer"
}

# ── 5. Hash verification ─────────────────────────────────────────────────────

Write-Section "5/5  Hash Verification (Quick-Install.ps1)"

$quickInstall = Get-Content "Quick-Install.ps1" -Raw -ErrorAction SilentlyContinue
if ($quickInstall -match '"[^"]+\.ps1"\s*=\s*"REPLACE_WITH_HASH"') {
    Write-Fail "Quick-Install.ps1 still contains placeholder hashes — run Get-FileHash and fill them in"
} else {
    # Check that each hash in Quick-Install.ps1 matches the local file
    $hashPattern = '"(?<name>[^"]+\.ps1)"\s*=\s*"(?<hash>[A-F0-9]{64})"'
    $matches = [regex]::Matches($quickInstall, $hashPattern)

    if ($matches.Count -eq 0) {
        Write-Warn "No hash entries found in Quick-Install.ps1"
    } else {
        foreach ($m in $matches) {
            $name     = $m.Groups['name'].Value
            $expected = $m.Groups['hash'].Value
            if (Test-Path $name) {
                $actual = (Get-FileHash $name -Algorithm SHA256).Hash
                if ($actual -eq $expected) {
                    Write-Pass "$name hash matches"
                } else {
                    Write-Fail "$name hash MISMATCH (file changed since last hash update)"
                    Write-Host "    Expected: $expected" -ForegroundColor Gray
                    Write-Host "    Actual:   $actual"   -ForegroundColor Gray
                    Write-Host "    Run: Get-FileHash $name -Algorithm SHA256" -ForegroundColor DarkGray
                }
            } else {
                Write-Warn "$name not found locally (hash not verified)"
            }
        }
    }
}

# ── Summary ──────────────────────────────────────────────────────────────────

Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "  RESULTS" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Passed:   $pass" -ForegroundColor Green
Write-Host "  Warnings: $warn" -ForegroundColor Yellow
Write-Host "  Failed:   $fail" -ForegroundColor $(if ($fail -gt 0) { 'Red' } else { 'Green' })
Write-Host "================================================================`n" -ForegroundColor Cyan

if ($fail -gt 0) {
    Write-Host "[BLOCKED] Fix the failures above before pushing." -ForegroundColor Red
    exit 1
} elseif ($warn -gt 0) {
    Write-Host "[OK] Tests passed with warnings — review before pushing." -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "[OK] All tests passed. Safe to push." -ForegroundColor Green
    exit 0
}
