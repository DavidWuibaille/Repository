# ⬆️ Windows 11 In-Place Upgrade (Batch)

## 🔧 What it does
- Prepares folders and log (`C:\exploit\log\migrationw11.log`)
- Runs **pending reboot check** (`upgrade_GetPendingReboot.cmd`) and **cleanup** (`upgrade_Cleanup.cmd`)
- Sets PowerShell **ExecutionPolicy Bypass**
- Detects OS **UI culture** and selects **install.wim index** (EN/ES/FR/IT/PT)
- Launches `setup.exe` **/quiet /auto Upgrade** using local `install.wim`, installs drivers from `C:\pnpdrivers`, **DynamicUpdate Disabled**, runs `upgrade_setupcomplete.cmd` at OOBE
- Reports status to **LANDesk/LDMS** via `SendTaskStatus.exe`
- Logs return code and removes `C:\MigrationW11` on failure

## ✅ Prerequisites
- Run as **Administrator**
- The script’s folder (`%~dp0`) must contain **Windows Setup**: `setup.exe`, `sources\install.wim`, and `upgrade_setupcomplete.cmd`
- Companion scripts present: `upgrade_GetPendingReboot.cmd`, `upgrade_Cleanup.cmd`
- **Drivers** in `C:\pnpdrivers`
- **LDMS** vars available: `LDMS_LOCAL_DIR`, `task_ID`; server name set in script (`ldcore.kiabi.fr`)
- Sufficient disk space; **no reboot pending**; network not required (DynamicUpdate disabled)