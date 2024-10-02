# Fonction pour écrire dans le log avec date et heure
function Write-Log {
    param (
        [string]$Message,
        [string]$LogFile = "C:\windows\temp\HPBiosUpdate.log"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp : $Message"
    Add-Content -Path $LogFile -Value $logMessage
}

# Créer le répertoire de log s'il n'existe pas
if (-not (Test-Path -Path "C:\Systools\OptLog")) {
    New-Item -Path "C:\Systools\OptLog" -ItemType Directory
}

# Importer le module
import-module HP.ClientManagement
Write-Log "Module HP.ClientManagement importé"

# Récupérer la version actuelle du BIOS
$BiosVer = Get-HPBIOSVersion
Write-Log "Version actuelle du BIOS: $BiosVer"

# Enregistrer la sortie de Get-HPBIOSUpdates
$HPBIOSUpdates = Get-HPBIOSUpdates
Write-Log "Résultat de Get-HPBIOSUpdates : $($HPBIOSUpdates | Out-String)"

# Convertir les versions en objets [Version]
$CurrentBiosVer = [Version]$BiosVer
$TargetBiosVer  = [Version]"2.20.01"

# Comparer les versions de manière appropriée
if ($CurrentBiosVer -lt $TargetBiosVer) {
    # Exécuter la mise à jour du BIOS si la version est inférieure
    Get-HPBIOSUpdates -Flash -Version "2.20.01" -Yes -BitLocker:suspend
    Write-Log "Mise à jour du BIOS lancée, version actuelle $BiosVer est inférieure à 2.20.01"
    Write-Host "Update BIOS need update $BiosVer"
} else {
    Write-Log "Mise à jour du BIOS ignorée, version actuelle $BiosVer est à jour"
    Write-Host "Bypass update BIOS"
}
