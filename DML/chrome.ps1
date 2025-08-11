# Variables
$baseUrl = "https://nas.wuibaille.fr/labo777/DML/chrome/"
$destinationFolder = "c:\windows\temp"

# Création du dossier de destination si nécessaire
if (-Not (Test-Path -Path $destinationFolder)) {
    New-Item -ItemType Directory -Path $destinationFolder | Out-Null
}

# Nom du fichier à télécharger
$file = "googlechromestandaloneenterprise64.msi"

# Téléchargement du fichier
$url = "$baseUrl$file"
$destinationFile = Join-Path -Path $destinationFolder -ChildPath $file

Write-Host "Downloading $url to $destinationFile..."
try {
    Invoke-WebRequest -Uri $url -OutFile $destinationFile -ErrorAction Stop
    Write-Host "$file downloaded successfully."
} catch {
    Write-Host "Failed to download $file. Error: $_" -ForegroundColor Red
    exit 1
}

# Installation silencieuse
Write-Host "Starting Google Chrome installation..."
try {
    $installCmd = "msiexec /i `"$destinationFile`" /qn /norestart"
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c $installCmd" -Wait -NoNewWindow

    Write-Host "Google Chrome installation completed successfully."
} catch {
    Write-Host "Installation failed. Error: $_" -ForegroundColor Red
    exit 1
}
