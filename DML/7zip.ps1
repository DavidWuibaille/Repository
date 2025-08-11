# Variables
$url = "https://nas.wuibaille.fr/labo777/DML/7zip/7z1900-x64.msi"
$outputFile = "$env:TEMP\7z1900-x64.msi"

# Téléchargement du fichier
Write-Host "Downloading $url to $outputFile..."
Invoke-WebRequest -Uri $url -OutFile $outputFile

# Vérification si le fichier a été téléchargé
if (Test-Path $outputFile) {
    Write-Host "File downloaded successfully."
    
    # Commande d'installation silencieuse
    $msiExecCmd = "msiexec.exe /i `"$outputFile`" /quiet /norestart"
    Write-Host "Installing 7-Zip silently..."
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$outputFile`" /quiet /norestart" -Wait

    # Vérification de l'installation
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Installation completed successfully."
    } else {
        Write-Host "Installation failed. Exit code: $LASTEXITCODE" -ForegroundColor Red
    }
} else {
    Write-Host "File download failed. Check the URL or internet connection." -ForegroundColor Red
}
