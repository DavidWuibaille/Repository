 Silent Uninstaller (PowerShell)

Removes installed apps by name using data from Windows **Uninstall** registry keys.  
Supports **MSI** (`msiexec /X {GUID}`) and **EXE** uninstallers with a custom silent switch.

## What it does
- Searches in:
  - `HKCU\Software\...\Uninstall`
  - `HKLM\Software\...\Uninstall`
  - `HKLM\Software\Wow6432Node\...\Uninstall`
- Detects MSI vs EXE uninstallers and runs them silently.
- Logs each action to `C:\Windows\temp\uninstall.log`.

## Usage
```powershell
# Syntax
Uninstall -AppName "<partial or full DisplayName>" [-Arg "<silent-args>"]

# Examples
Uninstall -AppName "Firefox"   -Arg "-ms"
Uninstall -AppName "TeamViewer"      # uses default /S
Uninstall -AppName "AnyDesk"
```

⚠️ Notes

- Run PowerShell **as Administrator**.  
- `-AppName` performs a **contains** match on `DisplayName` (may uninstall multiple apps if names overlap).  
- Silent switches vary by vendor; override with **`-Arg`** if needed.  
- MSI uninstalls run with `REBOOT=ReallySuppress /qn`, but a reboot may still be required. 