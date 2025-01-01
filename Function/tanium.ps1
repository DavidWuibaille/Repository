function TaniumDownloadAndInstallMsi {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Url, # URL du fichier MSI à télécharger

        [Parameter(Mandatory = $true)]
        [string]$Destination, # Chemin local où sauvegarder le fichier MSI

        [Parameter(Mandatory = $true)]
        [string]$AppName # Nom de l'application (pour les messages de progression et de log)
    )

    # Étape 1 : Téléchargement du fichier MSI
    Set-OSDProgressDisplay -Message "Apps $AppName Download"
    Log-Message "Apps $AppName Download from $Url"

    try {
        Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing
        Log-Message "Download of $AppName successful to $Destination"
    } catch {
        Log-Message "Download of $AppName failed: $_"
        exit 1
    }

    # Étape 2 : Installation du fichier MSI
    Set-OSDProgressDisplay -Message "Apps $AppName Install"
    Log-Message "Apps $AppName Install from $Destination"

    try {
        Start-Process "msiexec.exe" -ArgumentList "/i $Destination /quiet /norestart" -Wait -NoNewWindow
        Log-Message "Installation of $AppName successful"
    } catch {
        Log-Message "Installation of $AppName failed: $_"
        exit 1
    }
}


# Function to log messages
function Log-Message {
    param (
        [string]$message
    )
    if (Test-Path -Path "C:\") {  
        if (-not (Test-Path -Path "C:\Systools"))        { New-Item -Path "C:\Systools" -ItemType Directory } 
        if (-not (Test-Path -Path "C:\Systools\OptLog")) { New-Item -Path "C:\Systools\OptLog" -ItemType Directory }
    }
    $logFilePath = "C:\Systools\OptLog\Tanium.log"

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $message"
    Add-Content -Path $logFilePath -Value $logMessage
}


# Fonction : Récupérer des informations d'un ordinateur via une API
function Get-ComputerInfoFromAPI {
    param (
        [Parameter(Mandatory = $true)]
        [string]$WebServiceUrl # URL du service web
    )

    # Obtenir l'adresse MAC de l'interface réseau active
    try {
        $macAddresses = Get-WmiObject Win32_NetworkAdapter | Where-Object { $_.NetConnectionStatus -eq 2 } | Select-Object -ExpandProperty MACAddress
        $macAddresses = $macAddresses.replace(":", "").replace("-", "") # Nettoyer le format MAC
        Log-Message "MAC Addresses: $macAddresses"
    } catch {
        Log-Message "Erreur lors de l'obtention de l'adresse MAC : $_"
        return $null
    }

    # Construire l'URL de la requête
    $urlws = $WebServiceUrl + "?macaddress=" + $macAddresses
    Log-Message "URL construite : $urlws"

    # Appeler l'API et récupérer les informations
    try {
        $response = Invoke-RestMethod -Uri $urlws
        # Vérifier si une réponse valide est reçue
        if ($response.Computername) {
            Log-Message "Réponse reçue : ComputerName = $($response.Computername), Postype = $($response.postype), Keyboard = $($response.setkeyboard)"
            return @{
                Computername = $response.Computername
                Postype      = $response.postype
                SetKeyboard  = $response.setkeyboard
            }
        } else {
            Log-Message "Aucun ordinateur valide trouvé pour MAC $macAddresses"
            return $null
        }
    } catch {
        Log-Message "Erreur lors de la communication avec le service web : $_"
        return $null
    }
}

function InstallDrivers {
    # Tableau de correspondance modèle <-> URL de téléchargement
    $DriverUrls = @{
        "Dell Latitude 5410" = "https://example.com/drivers/Latitude_5410.zip"
        "Dell Latitude 7420" = "https://example.com/drivers/Latitude_7420.cab"
        "HP EliteBook 850 G8" = "https://example.com/drivers/EliteBook_850_G8.zip"
    }

    # Répertoire principal pour les fichiers de pilotes
    $basePath = "C:\Systools"
    $driverPath = "$basePath\Drivers"

    # Vérifier et créer les répertoires nécessaires
    if (-not (Test-Path $basePath)) {
        Write-Host "Création du répertoire : $basePath"
        New-Item -Path $basePath -ItemType Directory | Out-Null
    }
    if (-not (Test-Path $driverPath)) {
        Write-Host "Création du répertoire : $driverPath"
        New-Item -Path $driverPath -ItemType Directory | Out-Null
    }

    # Identifier le modèle de l'ordinateur
    try {
        $model = (Get-CimInstance -ClassName Win32_ComputerSystem).Model
        Write-Host "Modèle détecté : $model" -ForegroundColor Green
    } catch {
        Write-Host "Erreur lors de la détection du modèle de poste : $_" -ForegroundColor Red
        return
    }

    # Vérifier si le modèle existe dans le tableau
    if (-not $DriverUrls.ContainsKey($model)) {
        Write-Host "Aucun pilote trouvé pour le modèle : $model" -ForegroundColor Yellow
        return
    }

    # Télécharger le fichier associé au modèle
    $url = $DriverUrls[$model]
    $destination = "$driverPath\$(Split-Path -Leaf $url)"
    Write-Host "Téléchargement des pilotes depuis : $url" -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $url -OutFile $destination -UseBasicParsing
        Write-Host "Téléchargement terminé : $destination" -ForegroundColor Green
    } catch {
        Write-Host "Erreur lors du téléchargement des pilotes : $_" -ForegroundColor Red
        return
    }

    # Décompresser le fichier (ZIP ou CAB)
    Write-Host "Décompression des pilotes..."
    try {
        if ($destination -like "*.zip") {
            Expand-Archive -Path $destination -DestinationPath $driverPath -Force
        } elseif ($destination -like "*.cab") {
            $expandPath = "$driverPath\Expanded"
            if (-not (Test-Path $expandPath)) {
                New-Item -Path $expandPath -ItemType Directory | Out-Null
            }
            Expand-Cab -CabPath $destination -DestinationPath $expandPath
        } else {
            Write-Host "Format de fichier inconnu : $destination" -ForegroundColor Red
            return
        }
        Write-Host "Décompression terminée." -ForegroundColor Green
    } catch {
        Write-Host "Erreur lors de la décompression : $_" -ForegroundColor Red
        return
    }

    # Ajouter les pilotes avec DISM ou Add-WindowsDriver
    Write-Host "Injection des pilotes avec DISM..."
    try {
        $driverFolders = Get-ChildItem -Path $driverPath -Recurse -Directory
        foreach ($folder in $driverFolders) {
            dism /image:C:\ /Add-Driver /Driver:$($folder.FullName) /Recurse /ForceUnsigned
            Write-Host "Pilotes injectés depuis : $($folder.FullName)" -ForegroundColor Green
        }
        Write-Host "Injection des pilotes terminée." -ForegroundColor Green
    } catch {
        Write-Host "Erreur lors de l'injection des pilotes : $_" -ForegroundColor Red
    }
}


function SetDns {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$DnsServers # Liste des serveurs DNS à configurer
    )

    # Étape 1 : Détecter la carte réseau active
    Write-Host "Détection de la carte réseau active..." -ForegroundColor Cyan
    $ActiveCard = ""
    $AllCards = Get-NetAdapter

    foreach ($Card in $AllCards) {
        if (($Card.Status -eq "Up") -and ($Card.Name -notlike "*VMware*")) {
            if (($ActiveCard -eq "") -or ($ActiveCard -like "*wi")) {
                $ActiveCard = $Card.Name
            }
        }
    }

    if ($ActiveCard -eq "") {
        Write-Host "Aucune carte réseau active détectée." -ForegroundColor Red
        return
    }

    Write-Host "Carte réseau active détectée : $ActiveCard" -ForegroundColor Green

    # Étape 2 : Obtenir l'index de l'interface pour la carte réseau active
    Write-Host "Récupération de l'index de l'interface pour $ActiveCard..." -ForegroundColor Cyan
    $ActiveCardIndex = ""
    $IPInterfaces = Get-NetIPInterface

    foreach ($IPInterface in $IPInterfaces) {
        if (($IPInterface.InterfaceAlias -eq $ActiveCard) -and ($IPInterface.AddressFamily -eq "IPv4")) {
            $ActiveCardIndex = $IPInterface.ifIndex
        }
    }

    if ($ActiveCardIndex -eq "") {
        Write-Host "Impossible de récupérer l'index de l'interface pour $ActiveCard." -ForegroundColor Red
        return
    }

    Write-Host "Index de l'interface pour $ActiveCard : $ActiveCardIndex" -ForegroundColor Green

    # Étape 3 : Configurer les serveurs DNS
    Write-Host "Configuration des serveurs DNS : $($DnsServers -join ', ')" -ForegroundColor Cyan
    try {
        Set-DnsClientServerAddress -InterfaceIndex $ActiveCardIndex -ServerAddresses $DnsServers
        Write-Host "Les serveurs DNS ont été configurés avec succès." -ForegroundColor Green
    } catch {
        Write-Host "Erreur lors de la configuration des serveurs DNS : $_" -ForegroundColor Red
    }
}

