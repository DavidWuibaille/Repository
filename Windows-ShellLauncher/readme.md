# 🖥️ Configure Windows Shell Launcher

## 🔧 What it does
This script configures **Shell Launcher** to replace `explorer.exe` with a custom shell for specific users:
- Checks if the **Shell Launcher license** is enabled.
- Sets the **default shell** (`explorer.exe`) with a restart action if closed.
- Assigns a **custom shell (`c:\exploit\supervision.cmd`)** to user `w_supervision`.
- Enables Shell Launcher and verifies configuration.
- Optionally allows removing custom shells or disabling Shell Launcher.

---

## ✅ Prerequisites
- Run as **Administrator**.
- Requires **Windows IoT Enterprise** or an edition with **Shell Launcher feature enabled**.
- The account `w_supervision` must exist.
- Custom shell (`c:\exploit\supervision.cmd`) must be present.

---

## ⚠️ Notes
- Default exit actions available:  
  - `0` → Restart shell  
  - `1` → Restart device  
  - `2` → Shutdown device  
- Changing the default shell affects **all users without a custom shell**.
- Always test configuration on a **lab machine** before production.
- To remove or disable Shell Launcher, uncomment:
  ```powershell
  $ShellLauncherClass.RemoveCustomShell($Admins_SID)
  $ShellLauncherClass.RemoveCustomShell($Cashier_SID)
  $ShellLauncherClass.SetEnabled($FALSE)
  ```