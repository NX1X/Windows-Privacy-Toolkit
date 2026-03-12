# 🛡️ Windows Privacy Toolkit

> **Take control of your data. Disable telemetry. Protect your privacy.**

A lightweight PowerShell toolkit to audit and harden Windows 10/11 privacy settings. No bloat. Just scripts that work.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Windows 10/11](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?logo=windows)](https://www.microsoft.com/windows)
![Visitors](https://visitor-badge.laobi.icu/badge?page_id=NX1X.Windows-Privacy-Toolkit)

📚 **[Documentation](https://docs.nx1xlab.dev)** | 📝 **[Blog & Technical Guides](https://blog.nx1xlab.dev)** | 💻 **[GitHub Repository](https://github.com/NX1X/Windows-Privacy-Toolkit)**

---

## 📌 TL;DR

**One command. Full privacy.**

```powershell
iwr "https://raw.githubusercontent.com/NX1X/Windows-Privacy-Toolkit/main/Quick-Install.ps1" | iex
```

Or download manually and run:
```powershell
.\Install.ps1
```

> **Note:** Run in PowerShell. The script will automatically request admin privileges and download all necessary files.

Disables Windows telemetry, Recall AI, Copilot, Office tracking, and more. Tested on Windows 11. Should work on Windows 10 (not tested).

---

## 🎯 Why Privacy Matters

Every click, every app, every file you open—Windows is watching. By default, Microsoft collects:
- **Telemetry data** (your usage patterns)
- **Diagnostic information** (crashes, performance)
- **Advertising IDs** (for targeted ads)
- **Activity history** (timeline of everything you do)
- **Location data** (even on desktop)
- **Recall AI snapshots** (screenshots of everything you do - Win11 only)
- **Copilot interactions** (AI assistant data collection)
- **Office telemetry & logs** (document usage, features accessed)

**This toolkit disables all of that.**

---

## ⚡ Quick Start

### 🚀 One-Click Installation (Easiest - Recommended)
**`Install.ps1` is the main script that automatically runs everything for you:**
- ✅ Creates system restore point
- ✅ Runs audit (before)
- ✅ Executes all 3 hardening scripts
- ✅ Runs audit (after) 
- ✅ Generates detailed report
- ✅ Offers to restart

**How to use:**
1. Download the [latest release](https://github.com/NX1X/Windows-Privacy-Toolkit/releases)
2. Extract ZIP file
3. Open PowerShell and navigate to extracted folder
4. Run: `.\Install.ps1`
5. Script will automatically request admin privileges (UAC prompt)

---

### 📊 Manual Installation (Step-by-Step)
If you prefer to run scripts individually:

### 1️⃣ Audit Your Current Privacy Settings
```powershell
.\Privacy-Audit.ps1
```
See exactly what's enabled and what's leaking data.

### 2️⃣ Harden Everything at Once
```powershell
.\Disable-WindowsTelemetry.ps1
.\Disable-OfficeTelemetry.ps1
.\Disable-PowerShellTelemetry.ps1
```

### 3️⃣ Re-audit to Verify
```powershell
.\Privacy-Audit.ps1
```
All green checkmarks? You're protected. ✅

---

## 📦 What's Included

| Script | Purpose | Win 10 | Win 11 |
|--------|---------|--------|--------|
| `Privacy-Audit.ps1` | Comprehensive privacy audit (24 checks) | ✅ | ✅ |
| `Disable-WindowsTelemetry.ps1` | Disable OS-level telemetry & tracking (25 steps) | ✅ | ✅ |
| `Disable-OfficeTelemetry.ps1` | Disable Microsoft Office telemetry (9 steps) | ✅ | ✅ |
| `Disable-PowerShellTelemetry.ps1` | Disable PowerShell & developer tools telemetry (4 steps) | ✅ | ✅ |
| `Disable-AdvancedTelemetry.ps1` | **OPTIONAL** Advanced hardening (tasks/hosts/firewall) | ✅ | ✅ |
| `Remove-OfficeBloatware.ps1` | **OPTIONAL** Remove Microsoft 365 bloatware (OneDrive, Teams) | ✅ | ✅ |
| `Restore-PrivacySettings.ps1` | **RESTORE** Undo all changes & restore Windows defaults | ✅ | ✅ |

---

## 🔒 What Gets Disabled

### Core Privacy Features (Main Scripts)
- ✅ **Windows Telemetry** (set to Security/Off level)
- ✅ **Recall** (AI snapshot feature - Win11 only - **completely removed with payload**)
- ✅ **Copilot** (AI assistant)
- ✅ **Activity History & Timeline**
- ✅ **Advertising ID**
- ✅ **Location Tracking**
- ✅ **DiagTrack Service & Tracking Services**
- ✅ **Windows Spotlight** (lock screen ads)
- ✅ **Suggestions & Tips**
- ✅ **Feedback Notifications**

### New Privacy Features (v1.1)
- ✅ **WiFi Sense** (password sharing with contacts)
- ✅ **Web Search in Start Menu** (Bing integration)
- ✅ **Cloud Sync for Start Menu**
- ✅ **Windows Update P2P** (set to LAN-only, no internet upload)
- ✅ **Cortana** (voice assistant)
- ✅ **Search History & Bing Integration**
- ✅ **Microsoft Edge Telemetry & Copilot** (security features preserved)
- ✅ **Tracking Services** (dmwappushservice, RetailDemo, Xbox Live, etc.)
- ✅ **App Diagnostics Access**
- ✅ **Customer Experience Improvement Program (CEIP)**
- ✅ **Windows Store Suggestions**
- ✅ **Speech, Inking & Typing Personalization**
- ✅ **Steps Recorder & Remote Registry**
- ✅ **Microsoft Account Sync Settings**

### Office Privacy
- ✅ **Microsoft Office Telemetry**
- ✅ **Office Diagnostic Logs**
- ✅ **Office Connected Services**
- ✅ **Office Cloud Fonts**
- ✅ **Office Roaming Settings**
- ✅ **Office LinkedIn Integration**
- ✅ **Office Insights Services**
- ✅ **Office Research Pane**

### Developer Tools Privacy
- ✅ **PowerShell Telemetry**
- ✅ **VS Code Telemetry**
- ✅ **.NET Core Telemetry**
- ✅ **Windows Terminal Telemetry**

### Advanced Hardening (Optional Script)
- ✅ **Telemetry Scheduled Tasks** (15+ tasks disabled)
- ✅ **Hosts File Blocking** (35+ telemetry domains)
- ✅ **Firewall Rules** (outbound blocking)

### ⚠️ Security Features PRESERVED
- ✅ **SmartScreen** (malware/phishing protection) - **KEPT ENABLED**
- ✅ **Windows Defender** (cloud protection) - **KEPT ENABLED**
- ✅ **Windows Update** (no delays) - **WORKING NORMALLY**

---

## 🚀 Installation

### Method 1: Download Latest Release (Recommended)
1. Go to [Releases](https://github.com/NX1X/Windows-Privacy-Toolkit/releases)
2. Download `Windows-Privacy-Toolkit-vX.X.X.zip`
3. Extract and follow **How to Run** below

### Method 2: Clone the Repository
```powershell
git clone https://github.com/NX1X/Windows-Privacy-Toolkit.git
cd Windows-Privacy-Toolkit
```

### Method 3: Quick Install (One-liner)
```powershell
# Download and extract in one command
Invoke-WebRequest -Uri "https://github.com/NX1X/Windows-Privacy-Toolkit/archive/refs/heads/main.zip" -OutFile "toolkit.zip"; Expand-Archive -Path "toolkit.zip" -DestinationPath "."; cd Windows-Privacy-Toolkit-main
```

---

## ⚙️ Requirements

- Windows 10 or Windows 11
- PowerShell 5.1+ (built into Windows)
- **Administrator privileges** (for system-level changes)

**Testing Status:**
- ✅ **Tested on Windows 11** (25H2)
- ⚠️ **Should work on Windows 10** (not tested, but compatible)

---

## 📖 How to Run

### Prerequisites
- Windows 10 or Windows 11
- PowerShell 5.1+ (pre-installed on Windows)
- **Administrator privileges** required for hardening scripts

---

### Step 1: Download the Toolkit
**Option A: Clone with Git**
```powershell
git clone https://github.com/NX1X/Windows-Privacy-Toolkit.git
cd Windows-Privacy-Toolkit
```

**Option B: Download ZIP**
1. Click **Code** → **Download ZIP**
2. Extract to a folder (e.g., `C:\Privacy-Toolkit`)
3. Open that folder

---

### Step 2: Open PowerShell
1. Press `Win + X`
2. Select **Windows PowerShell** or **Terminal**
3. Navigate to the toolkit folder:
   ```powershell
   cd C:\Path\To\Windows-Privacy-Toolkit
   ```
4. Scripts will automatically request admin privileges when needed (UAC prompt)

---

### Step 3: Fix Execution Policy (If Needed)
If you get **"cannot be loaded because running scripts is disabled"**:

**Option 1 - Temporary (Recommended):**
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
```
This allows scripts ONLY in the current PowerShell window.

**Option 2 - Permanent:**
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```
Type `Y` and press Enter. This persists across PowerShell sessions.

---

### Step 4: Run the Scripts

**First, audit your current privacy settings:**
```powershell
.\Privacy-Audit.ps1
```

**Then, apply hardening:**
```powershell
.\Disable-WindowsTelemetry.ps1
.\Disable-OfficeTelemetry.ps1
.\Disable-PowerShellTelemetry.ps1
```

**Optional - Advanced Hardening:**
```powershell
.\Disable-AdvancedTelemetry.ps1
```
⚠️ **Warning**: This script offers 3 hardening levels. Level 2 & 3 may slow Windows Update checks by 30-60 seconds. Read the prompts carefully!

**Optional - Remove Microsoft 365 Bloatware:**
```powershell
.\Remove-OfficeBloatware.ps1
```
⚠️ **Note**: Removes pre-installed Microsoft 365 web apps, OneDrive, and Teams. Does NOT remove user-installed full Office applications.

**Finally, verify changes:**
```powershell
.\Privacy-Audit.ps1
```

**✅ All green checkmarks? You're protected!**

---

### Step 5: Restart (Recommended)
Some changes require a restart to take full effect:
```powershell
Restart-Computer
```

---

## 🛠️ Advanced Usage

### Automate on Fresh Windows Installs
Add to your setup script:
```powershell
# Download and run
iwr -Uri "https://raw.githubusercontent.com/NX1X/Windows-Privacy-Toolkit/main/Disable-WindowsTelemetry.ps1" | iex
```

### Schedule Regular Audits
```powershell
# Check privacy weekly
Register-ScheduledTask -TaskName "Privacy Audit" -Trigger (New-ScheduledTaskTrigger -Weekly -At 9am) -Action (New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\Path\To\Privacy-Audit.ps1")
```

---

## 📜 License

**MIT License** - Free for personal and commercial use.

**If you modify this code, please give credit to the original author.**

See [LICENSE](LICENSE) file for details.

---

## 👤 Author

**NX1X**
- 🌐 Website: [www.nx1xlab.dev](https://www.nx1xlab.dev)
- 🔧 Part of: [NXTools](https://www.nx1xlab.dev/nxtools)
- 📚 Documentation: [docs.nx1xlab.dev](https://docs.nx1xlab.dev)
- 📝 Blog & Technical Guides: [blog.nx1xlab.dev](https://blog.nx1xlab.dev)
- 💻 GitHub: [github.com/NX1X/Windows-Privacy-Toolkit](https://github.com/NX1X/Windows-Privacy-Toolkit)

---

## 🔄 Restoring Windows Defaults (Undo All Changes)

If you need to undo all privacy hardening and restore Windows to default settings:

```powershell
.\Restore-PrivacySettings.ps1
```

**What this script does:**
- ✅ Restores telemetry to Windows default (Full level)
- ✅ Re-enables all tracking services
- ✅ Restores Cortana, Activity History, Advertising ID
- ✅ Re-enables Office telemetry
- ✅ Restores developer tools telemetry
- ✅ Re-enables scheduled tasks
- ✅ Cleans hosts file (removes blocking entries)
- ✅ Removes firewall rules

**⚠️ Warning:** This will **RE-ENABLE** all telemetry and tracking. Only use if you want to return to default Windows privacy settings.

**Safety Features:**
- Requires typing 'YES' to confirm
- Backs up hosts file before modification
- Can be run multiple times safely

---

## ⚠️ Disclaimer

**USE AT YOUR OWN RISK.**

These scripts modify Windows registry settings and system configurations. 

**Testing & Compatibility:**
- ✅ Thoroughly tested on **Windows 11 (24H2)**
- ⚠️ Should work on **Windows 10** but **NOT tested**
- Most settings are compatible across both versions
- Recall feature is Windows 11 only (script handles this gracefully)

**Before running:**
- ✅ **Create a system restore point** (Install.ps1 does this automatically)
- ✅ **Review the scripts** before execution
- ✅ **Backup important data**
- ✅ **Understand the changes being made**

The author is not responsible for any issues arising from the use of these scripts. If you encounter problems, use System Restore to revert changes.

**Privacy is a right, not a privilege. Take it back.** 🛡️
