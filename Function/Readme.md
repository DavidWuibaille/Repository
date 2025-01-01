Étape 1 : Charger un script
Choisissez le script que vous souhaitez charger et exécutez la commande correspondante dans votre terminal PowerShell.

Charger les fonctions globales :

powershell
Copier le code
. ([scriptblock]::Create((Invoke-WebRequest -Uri "https://raw.githubusercontent.com/DavidWuibaille/Repository/main/Function/global.ps1").Content))
Charger les fonctions de packaging :

powershell
Copier le code
. ([scriptblock]::Create((Invoke-WebRequest -Uri "https://raw.githubusercontent.com/DavidWu
