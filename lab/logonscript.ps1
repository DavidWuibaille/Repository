# Définir les options en début de script
# Possibilités pour $ServiceOption : "Tanium", "Ivanti", "Tanium,Ivanti" ou "" (ne rien faire)
$ServiceOption = "Tanium,Ivanti"

# Possibilités pour $InstallOption : "Chrome", "7Zip", "Chrome,7Zip" ou "" (ne rien installer)
$InstallOption = "Chrome,7Zip"

# Convertir les variables en tableaux
$ServiceOptionList = $ServiceOption -split ',' | ForEach-Object { $_.Trim().ToLower() }
$InstallOptionList = $InstallOption -split ',' | ForEach-Object { $_.Trim().ToLower() }

# Fonction pour désactiver et arrêter des services
function Disable-ServiceByName ($ServiceName) {
    if (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue) {
        Write-Host "🔹 Désactivation et arrêt de $ServiceName..."
        Set-Service -Name $ServiceName -StartupType Disabled
        Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Service $ServiceName désactivé et arrêté."
    }
}

function Enable-ServiceByName ($ServiceName) {
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($service) {
        Write-Host "🔹 Activation et démarrage de $ServiceName..."
        Set-Service -Name $ServiceName -StartupType Automatic
        Start-Service -Name $ServiceName -ErrorAction SilentlyContinue
        Write-Host "✅ Service $ServiceName activé et démarré."
    } else {
        Write-Host "❌ Service $ServiceName introuvable."
    }
}


# Désactivation des services Tanium si sélectionné
if ($ServiceOptionList -contains "tanium") {
    Write-Host "✅ Désactivation et arrêt des services Tanium..."
    Disable-ServiceByName "Tanium Client"
    Disable-ServiceByName "TaniumDriverSvc"
} Else  {
    Enable-ServiceByName "Tanium Client"
    Enable-ServiceByName "TaniumDriverSvc" 
}
# Désactivation des services IVANTI si sélectionné
if ($ServiceOptionList -contains "ivanti") {
    Write-Host "✅ Désactivation et arrêt des services IVANTI..."
    $IvantiServices = Get-Service | Where-Object { $_.Name -match "^IVANTI" }
    
    if ($IvantiServices) {
        foreach ($service in $IvantiServices) {
            Disable-ServiceByName $service.Name
        }
    } else {
        Write-Host "❌ Aucun service IVANTI trouvé."
    }
} Else  {
    $IvantiServices = Get-Service | Where-Object { $_.Name -match "^IVANTI" }
    
    if ($IvantiServices) {
        foreach ($service in $IvantiServices) {
            Enable-ServiceByName $service.Name
        }
    } else {
        Write-Host "❌ Aucun service IVANTI trouvé."
    }


}

# Fonction pour installer des applications courantes
function Install-Application ($AppName) {
    if ($AppName -eq "chrome") {
        Write-Host "🔹 Installation de Google Chrome..."
        Start-Process -FilePath "winget" -ArgumentList "install --id Google.Chrome --silent --accept-package-agreements --accept-source-agreements" -NoNewWindow -Wait
        Write-Host "✅ Google Chrome installé."
    }
    elseif ($AppName -eq "7zip") {
        Write-Host "🔹 Installation de 7-Zip..."
        Start-Process -FilePath "winget" -ArgumentList "install --id 7zip.7zip --silent --accept-package-agreements --accept-source-agreements" -NoNewWindow -Wait
        Write-Host "✅ 7-Zip installé."
    }
}

# Installation des applications sélectionnées
if ($InstallOptionList -contains "chrome" -or $InstallOptionList -contains "7zip") {
    Write-Host "✅ Installation des applications demandées..."
    foreach ($app in $InstallOptionList) {
        Install-Application $app
    }
} else {
    Write-Host "ℹ️ Aucune application à installer."
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
        Disable-ServiceByName $service
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
