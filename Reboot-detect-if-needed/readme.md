# 🔄 Pending Reboot & User Notification Script

## 🔧 What it does
This PowerShell script checks if a reboot is pending and reacts accordingly:
- Detects **pending reboot conditions** from:
  - Windows Update  
  - Component-Based Servicing (CBS)  
  - Pending file rename operations  
  - MSI installer flag (`UpdateExeVolatile`)  
- Identifies the **currently logged-in user**.  
- If no user is logged in → **forces an immediate reboot** (if required).  
- If a user is logged in → sends a **notification message** asking to reboot.  

---

## ✅ Prerequisites
- Run as **Administrator**.  
- Requires **msg.exe** available (native in Windows).  
- Works on **Windows 10/11**.  

---

## ⚠️ Notes
- The script does **not force reboot** if a user is logged in → it only warns.  
- Customize the message in:  
  ```powershell
	$message = "Un redemarrage est en attente ----- Merci de redemarrer votre ordinateur."
  ```