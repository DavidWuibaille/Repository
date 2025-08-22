# USMT Start (Legacy HTA)

Legacy **HTA GUI** to run **USMT** backup/restore with a simple workflow.  
Select user profiles to back up, choose a source computer to restore, view logs, and launch helper tools.

## What it does
- Detects OS and picks the matching **USMT** binaries (x86/x64, Win7/8.1/10 paths).
- **Backup (scanstate)**: select users (auto‑excludes via `USMTStart.ini` and generated `USMTExcludeDrives.xml`), writes to `USMT\<COMPUTERNAME>\`.
- **Restore (loadstate)**: select a previous computer folder to import.
- Optional custom hooks: `Tools\commandeavant.bat` and `Tools\commandeapres.bat`.
- Opens logs with **Trace32** and views MIG content with **MigViewer**.
- Logs operations to `USMTstart.log`, `USMTBackup.log`, `USMTRestore.log`, `Custom*.log`.

## Files
- `USMTStartV4.3.hta` — main GUI  
- `USMTStart.ini` — exclusions (`[ExcludeUsers]`, etc.)  
- `Start.bat` — launcher (optional)  
- `Tools\` — USMT versions, `trace32.exe`, `MigViewer.exe`, `CustomBackup.vbs`, `CustomRestore.vbs`, `USMTExcludeDrives.*`, optional `commandeavant.bat` / `commandeapres.bat`

## Usage
- **Backup**: run the HTA → pick user profiles → **Backup**.  
- **Restore**: run the HTA → choose source computer → **Restore**.

### Command‑line (silent triggers)
- `USMTStartV4.3.hta BACKUP` — start backup immediately.  
- `USMTStartV4.3.hta RESTORE` — start restore for selected computer.  
- `USMTStartV4.3.hta RESTORE COMPUTER=<OldPCName>` — restore from a specific folder.

## Notes
- Requires **Windows Scripting Host** + **USMT** files present under `Tools\`.  
- Some operations may require **Administrator** rights.  
- Paths and tools are hard‑coded to the `Tools\` tree; adjust if you reorganize.