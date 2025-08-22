# 🖱️ HP G7/G8 Touchpad Issue in WinPE

On **HP ProBook G7/G8**, the **touchpad may not work in WinPE**.  
HP confirmed this is related to a **missing chipset driver**:  
👉 [HP Forum Reference](https://h30434.www3.hp.com/t5/Notebook-Boot-and-Lockup/HP-ProBook-450-G7-touchpad-not-working-detected/td-p/7591583)

---

## 🔧 Fix: Inject Drivers into WinPE

1. Mount the WinPE image:
   ```powershell
   dism /mount-wim /wimfile:"\\ServeurLDMS\ldmain\landesk\vboot\boot_x64.wim" /index:1 /mountdir:c:\mount
   ```
 
2. Inject the touchpad drivers:
   ```powershell
   Dism /Image:C:\mount /Add-Driver /Driver:"c:\WinPEDriversPbTouchPadx64" /Recurse
   ```

3. Commit and unmount:
   ```powershell
   Dism /unmount-wim /mountdir:c:\mount /commit
   ```
 
 ## ⚠️ Notes  
- Make sure the drivers in `c:\WinPEDriversPbTouchPadx64` are the correct ones for your HP model.  
- Always back up your original `boot.wim` before modification. 