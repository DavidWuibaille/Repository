# Récupérer le nom du produit Windows
$OSInfo = Get-WmiObject Win32_OperatingSystem
$OSName = $OSInfo.Caption

# Appliquer les optimisations de performance (toujours)
Write-Host "🔹 Ajustement des paramètres de performance..."
powercfg -change -monitor-timeout-ac 0  # Empêche l'écran de s’éteindre en mode secteur
powercfg -change -standby-timeout-ac 0  # Désactive la mise en veille
Write-Host "✅ Optimisation des performances appliquée."

# Vérifier si l'OS est un client Windows (Windows 10/11) et non un serveur
if ($OSName -match "Windows 10|Windows 11") {
    Write-Host "✅ Système d'exploitation client détecté ($OSName). Application des optimisations spécifiques..."

    # Désactiver le démarrage des services Tanium
    Set-Service -Name "Tanium Client" -StartupType Disabled
    Set-Service -Name "TaniumDriverSvc" -StartupType Disabled

    # Arrêter les services Tanium
    Stop-Service -Name "Tanium Client" -Force -ErrorAction SilentlyContinue
    Stop-Service -Name "TaniumDriverSvc" -Force -ErrorAction SilentlyContinue

    # Désactivation des services inutiles sur les OS clients (sauf Windows Update)
    Write-Host "🔹 Désactivation des services inutiles..."
    $servicesToDisable = @(
        "SysMain",          # Superfetch (préfetche inutile sur SSD)
        "DiagTrack",        # Télémétrie Microsoft
        "dmwappushservice"  # Service de télémétrie
    )

    foreach ($service in $servicesToDisable) {
        if (Get-Service -Name $service -ErrorAction SilentlyContinue) {
            Set-Service -Name $service -StartupType Disabled
            Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
            Write-Host "✅ Service $service désactivé."
        }
    }

    # Configuration d'un WSUS "fantôme" pour bloquer Windows Update sans désactiver le service
    Write-Host "🔹 Configuration d'un WSUS fantôme pour bloquer Windows Update..."
    $RegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
    if (!(Test-Path $RegPath)) {
        New-Item -Path $RegPath -Force | Out-Null
    }
    Set-ItemProperty -Path $RegPath -Name "WUServer" -Value "http://127.0.0.1" -Type String
    Set-ItemProperty -Path $RegPath -Name "WUStatusServer" -Value "http://127.0.0.1" -Type String
    Set-ItemProperty -Path $RegPath -Name "UseWUServer" -Value 1 -Type DWord
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWUServer" -Value 1 -Type DWord

    Write-Host "✅ WSUS fantôme configuré. Windows Update ne pourra pas contacter Microsoft."

    Write-Host "✅ Optimisations spécifiques aux OS clients terminées."
} else {
    Write-Host "❌ OS serveur détecté ($OSName). Aucune modification des services appliquée."
}

# Forcer la prise en compte des nouvelles configurations WSUS
Write-Host "🔄 Application des nouvelles configurations Windows Update..."
gpupdate /force
Write-Host "✅ Configuration WSUS appliquée."
