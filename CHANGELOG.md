# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

---

## [1.1.0] - 2026-03-12

### Security
- Added SHA256 hash verification for all downloaded scripts in `Quick-Install.ps1` — aborts and cleans up on mismatch
- Enforced TLS 1.2 (`[Net.SecurityProtocolType]::Tls12`) for all `Invoke-WebRequest` calls in `Quick-Install.ps1`
- Fixed script path single-quote injection vulnerability in self-elevation `Start-Process` blocks across all five main scripts
- Pinned all GitHub Actions to full commit SHA digests to prevent supply chain attacks (toolkit + website workflows)
- Added Content Security Policy (CSP) meta tag to website
- Replaced inline `onclick` event handler with `addEventListener` on website copy button
- Added `rel="noopener noreferrer"` to all external footer links on website

### Added
- `update-hashes.yml` workflow: automatically recomputes and commits SHA256 hashes whenever a downloaded script changes on `main`
- `Run-Tests.ps1`: local pre-push test runner (syntax, PSScriptAnalyzer, safety checks, hash verification)
- `Test-InSandbox.wsb` + `tests/Invoke-SandboxTest.ps1`: Windows Sandbox functional test suite that runs all hardening scripts and verifies registry/env changes
- `CHANGELOG.md`: Keep a Changelog format with full version history

### Changed
- `release.yml`: release notes now auto-extracted from `CHANGELOG.md` section matching the pushed tag
- `release.yml`: `CHANGELOG.md` added to required files check

---

## [1.0.1] - 2025-01-01

### Fixed
- Minor bug fixes and stability improvements

### Changed
- Updated documentation

---

## [1.0.0] - 2024-12-01

### Added
- `Install.ps1` — one-click automated installer with system restore point, before/after audit, and detailed report
- `Disable-WindowsTelemetry.ps1` — disables 25 Windows telemetry, tracking, and privacy-invasive settings
- `Disable-OfficeTelemetry.ps1` — disables Microsoft Office telemetry and connected services
- `Disable-PowerShellTelemetry.ps1` — opts out of PowerShell, VS Code, and .NET telemetry
- `Privacy-Audit.ps1` — comprehensive read-only audit of current privacy settings
- `Disable-AdvancedTelemetry.ps1` — optional advanced hardening (firewall rules, hosts file, scheduled tasks)
- `Restore-PrivacySettings.ps1` — reverts all changes made by the toolkit
- `Quick-Install.ps1` — one-liner remote installer for easy deployment
- GitHub Actions CI: syntax validation, PSScriptAnalyzer, Snyk security scanning

[Unreleased]: https://github.com/NX1X/Windows-Privacy-Toolkit/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/NX1X/Windows-Privacy-Toolkit/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/NX1X/Windows-Privacy-Toolkit/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/NX1X/Windows-Privacy-Toolkit/releases/tag/v1.0.0
