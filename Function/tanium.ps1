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
    write-host "-----------"
write-host $WebServiceUrl
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
    $urlws = "$WebServiceUrl?macaddress=$macAddresses"
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

