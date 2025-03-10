# Options de configuration
$ServiceOption = "Tanium,Ivanti"  # "Tanium", "Ivanti", "Tanium,Ivanti" ou "" (ne rien faire)
$InstallOption = "Chrome,7Zip"    # "Chrome", "7Zip", "Chrome,7Zip" ou "" (ne rien installer)

# Convertir les options en listes
$ServiceOptionList = $ServiceOption -split ',' | ForEach-Object { $_.Trim().ToLower() }
$InstallOptionList = $InstallOption -split ',' | ForEach-Object { $_.Trim().ToLower() }

# Fonction pour desactiver et arreter un service
function Disable-ServiceByName ($ServiceName) {
    if (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue) {
        Write-Host "Desactivation et arret de $ServiceName..."
        Set-Service -Name $ServiceName -StartupType Disabled
        Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
        Write-Host "Service $ServiceName desactive et arrete."
    }
}

# Fonction pour activer et demarrer un service
function Enable-ServiceByName ($ServiceName) {
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($service) {
        Write-Host "Activation et demarrage de $ServiceName..."
        Set-Service -Name $ServiceName -StartupType Automatic
        Start-Service -Name $ServiceName -ErrorAction SilentlyContinue
        Write-Host "Service $ServiceName active et demarre."
    }
}

# Gestion des services Tanium
if ($ServiceOptionList -contains "tanium") {
    Write-Host "Desactivation des services Tanium..."
    Disable-ServiceByName "Tanium Client"
    Disable-ServiceByName "TaniumDriverSvc"
} else {
    Write-Host "Activation des services Tanium..."
    Enable-ServiceByName "Tanium Client"
    Enable-ServiceByName "TaniumDriverSvc"
}

# Gestion des services IVANTI
$IvantiServices = Get-Service | Where-Object { $_.Name -like "ivanti*" }
if ($ServiceOptionList -contains "ivanti") {
    Write-Host "Desactivation des services IVANTI..."
    if ($IvantiServices) {
        foreach ($service in $IvantiServices) {
            Disable-ServiceByName $service.Name
        }
    } else {
        Write-Host "Aucun service IVANTI trouve."
    }
} else {
    Write-Host "Activation des services IVANTI..."
    if ($IvantiServices) {
        foreach ($service in $IvantiServices) {
            Enable-ServiceByName $service.Name
        }
    } else {
        Write-Host "Aucun service IVANTI trouve."
    }
}

# Fonction pour installer des applications
function Install-Application ($AppName) {
    if ($AppName -eq "chrome") {
        Write-Host "Installation de Google Chrome..."
        Start-Process -FilePath "winget" -ArgumentList "install --id Google.Chrome --silent --accept-package-agreements --accept-source-agreements" -NoNewWindow -Wait
        Write-Host "Google Chrome installe."
    }
    elseif ($AppName -eq "7zip") {
        Write-Host "Installation de 7-Zip..."
        Start-Process -FilePath "winget" -ArgumentList "install --id 7zip.7zip --silent --accept-package-agreements --accept-source-agreements" -NoNewWindow -Wait
        Write-Host "7-Zip installe."
    }
}

# Installation des applications selectionnees
if ($InstallOptionList -contains "chrome" -or $InstallOptionList -contains "7zip") {
    Write-Host "Installation des applications demandees..."
    foreach ($app in $InstallOptionList) {
        Install-Application $app
    }
} else {
    Write-Host "Aucune application a installer."
}

# Optimisation des performances (toujours appliquee)
Write-Host "Ajustement des parametres de performance..."
powercfg -change -monitor-timeout-ac 0
powercfg -change -standby-timeout-ac 0
Write-Host "Optimisation des performances appliquee."

# Detection du type d'OS (Client vs Serveur)
$OSInfo = Get-WmiObject Win32_OperatingSystem
$OSName = $OSInfo.Caption

if ($OSName -match "Windows 10|Windows 11") {
    Write-Host "OS client detecte ($OSName). Application des optimisations..."

    # Desactiver certains services inutiles
    $servicesToDisable = @("SysMain", "DiagTrack", "dmwappushservice")
    foreach ($service in $servicesToDisable) {
        Disable-ServiceByName $service
    }

    # Configuration d'un WSUS fantome pour bloquer Windows Update
    Write-Host "Configuration d'un WSUS fantome..."
    $RegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
    if (!(Test-Path $RegPath)) {
        New-Item -Path $RegPath -Force | Out-Null
    }
    Set-ItemProperty -Path $RegPath -Name "WUServer" -Value "http://127.0.0.1" -Type String
    Set-ItemProperty -Path $RegPath -Name "WUStatusServer" -Value "http://127.0.0.1" -Type String
    Set-ItemProperty -Path $RegPath -Name "UseWUServer" -Value 1 -Type DWord
    Set-ItemProperty -Path "$RegPath\AU" -Name "UseWUServer" -Value 1 -Type DWord
    Write-Host "WSUS fantome configure."

    # Desactivation du Pare-feu Windows
    Write-Host "Desactivation du Pare-feu Windows..."
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
    Write-Host "Pare-feu Windows desactive."

    # Desactivation de Microsoft Defender
    Write-Host "Desactivation de Microsoft Defender..."
    $DefenderRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
    if (!(Test-Path $DefenderRegPath)) {
        New-Item -Path $DefenderRegPath -Force | Out-Null
    }
    Set-ItemProperty -Path $DefenderRegPath -Name "DisableAntiSpyware" -Value 1 -Type DWord
    Set-ItemProperty -Path $DefenderRegPath -Name "DisableRealtimeMonitoring" -Value 1 -Type DWord
    Write-Host "Microsoft Defender desactive."

    # Appliquer les parametres immediatement
    Write-Host "Application des nouvelles configurations..."
    gpupdate /force
    Write-Host "Toutes les modifications ont ete appliquees."
} else {
    Write-Host "OS serveur detecte ($OSName). Seules les optimisations de performance sont appliquees."
}
