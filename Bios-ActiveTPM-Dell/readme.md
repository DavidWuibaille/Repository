# Enable TPM on Dell Systems

This PowerShell script enables **TPM (Trusted Platform Module)** on Dell machines using the official **DellBIOSProvider** PowerShell module.

## ✨ Features
- Detects if the **DellBIOSProvider** module is installed  
- Enables TPM security in BIOS  
- Supports optional BIOS password parameter  

## 📌 Requirements
- Windows with PowerShell  
- [DellBIOSProvider module](https://www.powershellgallery.com/packages/DellBIOSProvider) installed  
- Administrator privileges  

## 🚀 Usage
Run in an elevated PowerShell session:

```powershell
.\Enable-TPM_Dell.ps1
```
If BIOS is password-protected:

```powershell
.\Enable-TPM_Dell.ps1 -BiosPassword "YourPassword"
```