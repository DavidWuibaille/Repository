# 🔑 Windows OEM Activation Script

## 🔧 What it does
- Reads the **embedded OEM product key** from BIOS.
- Installs the key and **activates Windows** (`slmgr -ipk` then `-ato`).
- Checks activation status and displays a short result.

## ✅ Prerequisites
- Run as **Administrator**.
- Internet access for online activation (KMS/MAK not required for OEM key).
- Works on Windows 10/11 with an **OA3** (BIOS‑embedded) key.

🔗 More details: **[Windows 11 OEM Activation](https://blog.wuibaille.fr/2023/05/activation-oem-windows-11/)**