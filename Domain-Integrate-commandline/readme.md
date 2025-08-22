# Domain Join Helper (Batch)

Batch script to **configure DNS (optional)**, relax PowerShell execution policy for the session, and **join a Windows machine to an AD domain** using `netdom`.

## 📂 Files
- `JoinDomain.cmd` — main batch script  
- `SetDNS.ps1` — optional DNS configuration helper (called by the batch)

## ⚙️ What it does
1. Executes `SetDNS.ps1` (optional) to force lab DNS.  
2. Calls `netdom JOIN` to add the computer to the domain.  