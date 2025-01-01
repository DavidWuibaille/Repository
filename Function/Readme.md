# PowerShell Functions: Global.ps1

This repository contains useful PowerShell functions that can be directly loaded into your scripts or PowerShell session from the provided URL.

## How to Use

You can load the functions defined in `global.ps1` directly into your PowerShell session or scripts by using the following command:

```powershell
# URL of the script
$url = "https://raw.githubusercontent.com/DavidWuibaille/Repository/main/Function/global.ps1"

# Load and execute the script in the current session
. ([scriptblock]::Create((Invoke-WebRequest -Uri $url).Content))
