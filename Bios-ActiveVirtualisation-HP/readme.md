# HP BIOS – Enable Virtualization

This PowerShell script uses **WMI (hp_biosEnumeration + hp_biossettinginterface)** to enable virtualization options directly in the BIOS of HP systems.

## ✨ Features
- Connects to HP BIOS via `root/hp/instrumentedBIOS`
- Reads current settings with `hp_biosEnumeration`
- Enables:
  - **Virtualization Technology (VTx)**
  - **Virtualization Technology for Directed I/O (VTd)**

## 📌 Requirements
- HP device with BIOS supporting these options  
- Windows PowerShell (Run as Administrator)  
- WMI namespace `root/hp/instrumentedBIOS` available  

## 🚀 Usage
Run the script in an elevated PowerShell console:

```powershell
powershell -ExecutionPolicy Bypass -File .\Enable-Virtualization.ps1
```

The script will:

- Display current **VTx** and **VTd** values  
- Enable them if disabled  

⚠️ Notes

- Some changes may require a **system reboot** to take effect.  
- If the BIOS is password-protected, additional parameters may be needed to provide credentials.  
- These WMI classes are specific to **HP devices** and will not work on other vendors.  
