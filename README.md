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
| `Privacy-Audit.ps1` | Comprehensive privacy audit | ✅ | ✅ |
| `Disable-WindowsTelemetry.ps1` | Disable OS-level telemetry & tracking | ✅ | ✅ |
| `Disable-OfficeTelemetry.ps1` | Disable Microsoft Office telemetry | ✅ | ✅ |
| `Disable-PowerShellTelemetry.ps1` | Disable PowerShell telemetry | ✅ | ✅ |

---

## 🔒 What Gets Disabled

- ✅ **Windows Telemetry** (set to Security/Off level)
- ✅ **Recall** (AI snapshot feature - Win11 only)
- ✅ **Copilot** (AI assistant)
- ✅ **Activity History & Timeline**
- ✅ **Advertising ID**
- ✅ **Location Tracking**
- ✅ **DiagTrack Service**
- ✅ **Windows Spotlight** (lock screen ads)
- ✅ **Suggestions & Tips**
- ✅ **Microsoft Office Telemetry**
- ✅ **Office Diagnostic Logs**
- ✅ **Office Connected Services**
- ✅ **PowerShell Telemetry**

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

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```
Type `Y` and press Enter.

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

## 🤝 Contributing

Found a bug? Want to add more privacy checks?

1. Fork the repo
2. Create your feature branch (`git checkout -b feature/NewPrivacyCheck`)
3. Commit your changes (`git commit -m 'Add new privacy check'`)
4. Push to the branch (`git push origin feature/NewPrivacyCheck`)
5. Open a Pull Request

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

---

## 🌟 Star This Repo

If this toolkit helped you, give it a ⭐ on GitHub!

---

**Privacy is a right, not a privilege. Take it back.** 🛡️
