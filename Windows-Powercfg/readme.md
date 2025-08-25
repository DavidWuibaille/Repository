# 🔋 Windows Power Configuration Script

## 🔧 What it does
This script sets custom **power settings** using `powercfg`:
- Turns off the **display after 15 minutes** (AC & battery).
- Disables **disk timeout** (never turn off disks).
- Disables **sleep/standby** (AC & battery).
- Disables **hibernation** (AC & battery).

---

## ⚠️ Notes
- Requires **administrator rights**.  
- Settings apply to the **active power plan**.  
- You can adjust values (in minutes) if needed, e.g.:
  ```batch
  powercfg -change -monitor-timeout-ac 10
  ```