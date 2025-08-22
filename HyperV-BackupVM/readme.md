# Hyper-V VM Backup Script

This PowerShell script automates the **export and backup of Hyper-V virtual machines** whose names contain `Backup_`.

## ✨ Features
- Creates and cleans a temporary **export directory**
- Exports all VMs matching `*Backup_*`
- Copies the exported files to a **network backup path**
- Cleans up the temporary export folder after transfer
- Provides console messages for progress and errors

## 📌 Requirements
- Windows with Hyper-V role installed
- Run PowerShell as **Administrator**
- Access to the network share defined in `$backupPath`

## 🚀 Usage
1. Adjust the paths in the script:
   ```powershell
   $exportPath = "D:\export"
   $backupPath = "\\192.168.0.3\backup\VM"
   ```
   
2. Run the script:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\Backup-HyperV.ps1
   ```

3. All VMs with Backup_ in their name will be exported and copied to the backup location.

⚠️ Notes

- The export folder ($exportPath) is cleared before and after each run.
- Ensure enough free space in the export directory.
- Network connectivity and write permissions to $backupPath are required.