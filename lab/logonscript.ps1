# Options de configuration
$ServiceStopOption = "Tanium"  # Services a desactiver et arreter
$ServiceStartOption = "Ivanti"              # Services a activer et demarrer (ex: "Tanium,Ivanti")
$InstallOption = "Chrome,7Zip"        # Applications a installer ("Chrome", "7Zip", "Chrome,7Zip" ou "")

# Convertir les options en listes
$ServiceStopList = $ServiceStopOption -split ',' | ForEach-Object { $_.Trim().ToLower() }
$ServiceStartList = $ServiceStartOption -split ',' | ForEach-Object { $_.Trim().ToLower() }
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

# Gestion des services Tanium
if ($ServiceStopList -contains "tanium") {
    Disable-ServiceByName "Tanium Client"
    Disable-ServiceByName "TaniumDriverSvc"
}
if ($ServiceStartList -contains "tanium") {
    Enable-ServiceByName "Tanium Client"
    Enable-ServiceByName "TaniumDriverSvc"
}

# Gestion des services IVANTI
$IvantiServices = Get-Service | Where-Object { $_.DisplayName -like "Ivanti*" }
if ($ServiceStopList -contains "ivanti") {
    if ($IvantiServices) {
        foreach ($service in $IvantiServices) { Disable-ServiceByName $service.Name }
    }
}
if ($ServiceStartList -contains "ivanti") {
    if ($IvantiServices) {
        foreach ($service in $IvantiServices) { Enable-ServiceByName $service.Name }
    } 
}

# Installation des applications selectionnees
Write-Host "Installation des applications demandees..."
foreach ($app in $InstallOptionList) {
    Install-Application $app
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

    # Disable unnecessary services
    $servicesToDisable = @(
        "SysMain",
        "DiagTrack",
        "dmwappushservice",
        "WSearch",                   # Windows Search
        "MapsBroker",                # Downloaded Maps Manager
        "RetailDemo"                 # Retail Demo Service
    )
    foreach ($service in $servicesToDisable) {
        Get-Service -Name $service -ErrorAction SilentlyContinue | Set-Service -StartupType Disabled -ErrorAction SilentlyContinue
    }
    
    # Disable Windows Firewall
    Write-Host "Disabling Windows Firewall..."
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
    Write-Host "Windows Firewall disabled."
    
    # Disable Windows Defender Real-time Protection
    Write-Host "Disabling Windows Defender Real-time Protection..."
    Set-MpPreference -DisableRealtimeMonitoring $true
    
    # Disable scheduled tasks for telemetry
    Write-Host "Disabling scheduled telemetry tasks..."
    Get-ScheduledTask -TaskPath "\Microsoft\Windows\Application Experience\" | Disable-ScheduledTask -ErrorAction SilentlyContinue
    Get-ScheduledTask -TaskPath "\Microsoft\Windows\Customer Experience Improvement Program\" | Disable-ScheduledTask -ErrorAction SilentlyContinue
    
    # Adjust visual effects for performance
    Write-Host "Optimizing visual effects for performance..."
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Name 'VisualFXSetting' -Value 2
    
    # Set power plan to High Performance
    Write-Host "Setting power plan to High Performance..."
    powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    
    # Disable hibernation to save disk space
    Write-Host "Disabling hibernation..."
    powercfg -h off
    
    # Disable system restore
    Write-Host "Disabling system restore..."
    Disable-ComputerRestore -Drive "C:\"
    
    # Disable indexing on C drive
    Write-Host "Disabling indexing on drive C..."
    Get-WmiObject -Class Win32_Volume -Filter "DriveLetter = 'C:'" | Set-WmiInstance -Arguments @{IndexingEnabled=$false}

    # Appliquer les parametres immediatement
    Write-Host "Application des nouvelles configurations..."
    gpupdate /force
    Write-Host "Toutes les modifications ont ete appliquees."
} else {
    Write-Host "OS serveur detecte ($OSName). Seules les optimisations de performance sont appliquees."
}
