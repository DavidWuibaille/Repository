# 🧹 Windows Component & Disk Cleanup Script

## 🔧 What it does
- On **Windows 10**, runs **DISM** component store cleanup:
  - `/AnalyzeComponentStore` then `/StartComponentCleanup /ResetBase`
- Deletes `C:\Windows\Temp\*`
- Preconfigures **Disk Cleanup** (CleanMgr) options via registry (`StateFlags1234`)
  and runs `cleanmgr.exe /SAGERUN:1234` to purge:
  - Previous Windows installations, Update cleanup, driver packages, thumbnails,
    WER files, ESD setup files, upgrade logs, etc.
- Uses **Sysnative** redirection when launched from 32‑bit context

## ✅ Prerequisites
- Run as **Administrator**
- Target **Windows 10** for the DISM step (script skips it otherwise)
- This is **destructive cleanup**: it may remove *Windows.old*, cached updates,
  minidumps, and other data; ensure you don’t need rollback files