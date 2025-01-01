# PowerShell Functions: Global.ps1

This repository contains useful PowerShell functions that can be directly loaded into your scripts or PowerShell session from the provided URL.

## How to Use

You can load the functions defined in `global.ps1` directly into your PowerShell session or scripts by using the following command:

```powershell
# Charger et exécuter le script Packaging.ps1 depuis l'URL brute
. ([scriptblock]::Create((Invoke-WebRequest -Uri "https://raw.githubusercontent.com/DavidWuibaille/Repository/main/Function/Packaging.ps1").Content))

# Charger et exécuter un autre script global.ps1 (par exemple)
. ([scriptblock]::Create((Invoke-WebRequest -Uri "https://raw.githubusercontent.com/DavidWuibaille/Repository/main/Function/global.ps1").Content))

