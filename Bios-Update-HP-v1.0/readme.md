# HP BIOS Update (Batch)

Automates **HP BIOS** updates using HP tools (`HpFirmwareUpdRec.exe` / `HPBIOSUPDREC.exe`) and optional `install.cmd`, with consistent logging and exit handling.

## How it works
- Detects architecture to call proper binaries (`sysnative` when needed).
- Finds the **first subfolder** next to the script and treats it as the **BIOS package folder**.
- Cleans previous `HpFirmwareUpdRec.log`, then runs:
  - `HpFirmwareUpdRec.exe -s -r -h -b -f"<folder>"` if present
  - `HPBIOSUPDREC.exe -s -b -r -a` if present
  - `install.cmd` if present
- Writes detailed logs to **`C:\pnpDrivers\BIOS.log`** (including result code).

## Exit codes (mapped)
- **3010** → SUCCESS: *Reboot required*  
- **1602** → CANCEL: *Dependency prevents completion*  
- **273** → CANCEL: *Same BIOS version (no update)*  
- **282** → CANCEL: *Attempted downgrade (older version)*

## Requirements
- Run as **Administrator**.
- Place HP BIOS package files in a **subfolder** next to the `.cmd/.bat`.
- Supported tools inside that folder: `HpFirmwareUpdRec.exe` and/or `HPBIOSUPDREC.exe` (from HP).

