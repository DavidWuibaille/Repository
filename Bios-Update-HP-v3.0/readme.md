# 🚀 BIOS Update – Staged & Scheduled

## 🔧 What it does
- Copies the **entire folder** next to the script to `C:\Windows\Temp\Bios`
- Cleans previous **HpFirmwareUpdRec logs** and `ldcacheinfo`
- Creates a **scheduled task** `BiosUpdateAtStartup` that runs
  `C:\Windows\Temp\Bios\BIOS_Update.bat` **at startup with a 2-minute delay** (as SYSTEM, highest)

## ✅ Prerequisites
- Run as **Administrator**
- Ensure `BIOS_Update.bat` exists in the source folder (it will be copied to `C:\Windows\Temp\Bios`)
- Include the HP package folder (e.g. `sp156628\...`) expected by `BIOS_Update.bat`
- Machine will execute the BIOS update **on next boot** via the scheduled task

