# Définir l'option en début de script
# "Tanium" = Désactiver les services Tanium
# "Ivanti" = Désactiver les services qui commencent par "IVANTI"
# "None" = Ne rien faire
$ServiceOption = "Tanium"  # Change cette valeur selon ton besoin

# Vérifier et appliquer l'option choisie
if ($ServiceOption -eq "Tanium") {
    Write-Host "✅ Désactivation et arrêt des services Tanium..."
    Set-Service -Name "Tanium Client" -StartupType Disabled
    Set-Service -Name "TaniumDriverSvc" -StartupType Disabled

    Stop-Service -Name "Tanium Client" -Force -ErrorAction SilentlyContinue
    Stop-Service -Name "TaniumDriverSvc" -Force -ErrorAction SilentlyContinue
    Write-Host "✅ Services Tanium désactivés et arrêtés."
}
elseif ($ServiceOption -eq "Ivanti") {
    Write-Host "✅ Recherche des services IVANTI..."
    $IvantiServices = Get-Service | Where-Object { $_.Name -match "^IVANTI" }

    if ($IvantiServices) {
        foreach ($service in $IvantiServices) {
            Write-Host "🔹 Désactivation et arrêt de $($service.Name)..."
            Set-Service -Name $service.Name -StartupType Disabled
            Stop-Service -Name $service.Name -Force -ErrorAction SilentlyContinue
        }
        Write-Host "✅ Tous les services IVANTI ont été désactivés et arrêtés."
    } else {
        Write-Host "❌ Aucun service IVANTI trouvé."
    }
}
else {
    Write-Host "ℹ️ Aucun service désactivé. Le script continue..."
}

# Appliquer les optimisations de performance (toujours)
Write-Host "🔹 Ajustement des paramètres de performance..."
powercfg -change -monitor-timeout-ac 0  # Empêche l'écran de s’éteindre en mode secteur
powercfg -change -standby-timeout-ac 0  # Désactive la mise en veille
Write-Host "✅ Optimisation des performances appliquée."

# Vérifier si l'OS est un client Windows (Windows 10/11) et non un serveur
$OSInfo = Get-WmiObject Win32_OperatingSystem
$OSName = $OSInfo.Caption

if ($OSName -match "Windows 10|Windows 11") {
    Write-Host "✅ Système d'exploitation client détecté ($OSName). Application des optimisations spécifiques..."

    # Désactivation des services inutiles sur les OS clients
    Write-Host "🔹 Désactivation des services inutiles..."
    $servicesToDisable = @(
        "SysMain",          # Superfetch (inutile sur SSD)
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
    Write-Host "✅ WSUS fantôme configuré."

    # Désactivation du Pare-feu Windows
    Write-Host "🔹 Désactivation du Pare-feu Windows..."
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
    Write-Host "✅ Pare-feu Windows désactivé."

    # Désactivation de Windows Defender via la base de registre
    Write-Host "🔹 Désactivation de l'Antivirus Microsoft Defender..."
    $DefenderRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
    if (!(Test-Path $DefenderRegPath)) {
        New-Item -Path $DefenderRegPath -Force | Out-Null
    }
    Set-ItemProperty -Path $DefenderRegPath -Name "DisableAntiSpyware" -Value 1 -Type DWord
    Set-ItemProperty -Path $DefenderRegPath -Name "DisableRealtimeMonitoring" -Value 1 -Type DWord
    Write-Host "✅ Microsoft Defender désactivé."

    # Forcer l'application des stratégies
    Write-Host "🔄 Application des nouvelles configurations..."
    gpupdate /force
    Write-Host "✅ Toutes les modifications ont été appliquées."
} else {
    Write-Host "❌ OS serveur détecté ($OSName). Seules les optimisations de performance sont appliquées."
}
