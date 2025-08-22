# Hyper-V Guest Script Runner (GUI)

![Hyper-V Script Runner](readme.png)

A PowerShell **WinForms GUI** to run `.ps1` scripts inside selected Hyper-V VMs using **PowerShell Direct**.  
It fetches scripts from a remote repository and executes them in guest OSes with provided credentials.

## ✨ Features
- List all **running Hyper-V VMs**
- Fetch `.ps1` scripts dynamically from a remote URL  
  *(default: `https://nas.wuibaille.fr/WS/postype/`)*  
- Prompt for **guest credentials**
- Run the selected script in one or multiple VMs
- Option to run **gpupdate /force** after script execution
- Logs output for each VM in a GUI textbox with timestamps

## 📌 Requirements
- Windows 10/11 with **Hyper-V** role enabled
- PowerShell 5.1 or 7+
- PowerShell Direct enabled (run on the Hyper-V host)
- Access to the remote URL hosting `.ps1` scripts
- Run script as **Administrator**

## 🚀 Usage
1. Launch the script on the **Hyper-V host**:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\HyperV-GuestScriptRunner.ps1
   ```


Enter guest **username and password**.  

Refresh and select **scripts** from the remote repository.  

Select one or multiple **running VMs**.  

(Optional) Check **Run gpupdate /force**.  

Click **Run on Selected VMs**.  

The **log panel** will display progress and results per VM.  

⚠️ Notes

- Requires **network access** to the script repository.  
- Guest VMs must allow login with the specified **credentials**.  
- If a VM is not accessible via **PowerShell Direct**, execution will fail for that VM.  
- Script errors and exit codes are **logged in the GUI**.   