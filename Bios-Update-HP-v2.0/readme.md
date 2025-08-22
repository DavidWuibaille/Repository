# HP BIOS Update Script (PowerShell)

This PowerShell script automates **HP BIOS updates** using the **HP.ClientManagement** module.  
It compares the current BIOS version with a target version and applies the update if necessary, while logging all actions.

## ✨ Features
- Imports **HP.ClientManagement** module
- Logs all steps to `C:\windows\temp\HPBiosUpdate.log`
- Retrieves and displays the current BIOS version
- Checks available updates with `Get-HPBIOSUpdates`
- Compares against a **target version** (`2.20.01` in this example)
- Runs update automatically if the current BIOS is outdated, with BitLocker suspend

## 📌 Requirements
- Windows with PowerShell (run as Administrator)
- HP device with **HP.ClientManagement** module installed
- Access to HP BIOS update packages

## 🚀 Usage
1. Edit the script and set the **target BIOS version**:
```powershell
$TargetBiosVer  = [Version]"2.20.01"
```
   
2. Run the script:
```powershell
powershell -ExecutionPolicy Bypass -File .\HpBiosUpdate.ps1
```

## ⚠️ Notes
- The script suspends **BitLocker** before flashing the BIOS.  
- A **reboot is usually required** after the update completes.  
- If the current BIOS version is equal to or newer than the target, the update is skipped.  
- All actions and results are logged in `C:\windows\temp\HPBiosUpdate.log`