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
