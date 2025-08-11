# Variables
$baseUrl = "https://nas.wuibaille.fr/labo777/DML/AdobeReaderDC/"
$destinationFolder = "$env:TEMP\AdobeReaderDC"

# Création du dossier de destination si nécessaire
if (-Not (Test-Path -Path $destinationFolder)) {
    New-Item -ItemType Directory -Path $destinationFolder | Out-Null
}

# Liste des fichiers à télécharger
$files = @(
    "AcroRdrDCUpd2001320064_MUI.msp",
    "AcroRead.msi",
    "AcroRead.mst",
    "AcroRead.ref",
    "Data1.cab",
    "setup.exe",
    "setup.ini"
)

# Téléchargement des fichiers
foreach ($file in $files) {
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
}

# Installation silencieuse des fichiers
Write-Host "Starting Adobe Reader DC installation..."
try {
    # Installation de la base
    $installCmd = "msiexec /i `"$destinationFolder\AcroRead.msi`" TRANSFORMS=`"$destinationFolder\AcroRead.mst`" /qn /lie `"C:\windows\temp\INSTALL_AdobeReaderDC_20200615_BASE.log`" REBOOT=ReallySuppress"
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c $installCmd" -Wait -NoNewWindow

    # Application du patch
    $patchCmd = "msiexec /p `"$destinationFolder\AcroRdrDCUpd2001320064_MUI.msp`" /qn /lie `"C:\windows\temp\INSTALL_AcroRdrDCUpd2001320064_MSP.log`" REBOOT=ReallySuppress"
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c $patchCmd" -Wait -NoNewWindow

    Write-Host "Adobe Reader DC installation completed successfully."
} catch {
    Write-Host "Installation failed. Error: $_" -ForegroundColor Red
    exit 1
}
