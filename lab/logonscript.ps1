# Configuration options
$InstallOption = "chrome,7Zip,clientivanti,clienttanium,clientsccm,clientkace"  # Applications to install
$UninstallOption = "Chrome"  # Applications to uninstall
$WebShareURL = "https://nas.wuibaille.fr/labo777/DML/"
$DownloadBasePath = "C:\Windows\Temp\DML"

# Convert options into lists
$InstallOptionList = $InstallOption -split ',' | ForEach-Object { $_.Trim().ToLower() }
$UninstallOptionList = $UninstallOption -split ',' | ForEach-Object { $_.Trim().ToLower() }

# Function to download all files in a web folder recursively
function Download-Folder {
    param (
        [string]$URL,                # URL du dossier à télécharger
        [string]$Destination         # Dossier local de destination
    )

    # Vérifier et créer le dossier de destination si nécessaire
    if (-not (Test-Path -Path $Destination)) {
        New-Item -ItemType Directory -Path $Destination | Out-Null
    }
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12, [Net.SecurityProtocolType]::Tls13

    write-host "Invoke-WebRequest -Uri $URL -UseBasicParsing"
    # Récupérer le contenu HTML du dossier web
    try {
        $html = Invoke-WebRequest -Uri $URL -UseBasicParsing
    } catch {
        Write-Host "Impossible d'accéder au dossier web : $URL" -ForegroundColor Red
        return
    }

    # Extraire les liens en filtrant les fichiers uniquement
    $links = $html.Links | Where-Object { $_.href -notmatch "^\?|\/$|@eaDir" }

    if ($links.Count -eq 0) {
        Write-Host "Aucun fichier à télécharger depuis : $URL" -ForegroundColor Yellow
        return
    }

    # Télécharger chaque fichier
    foreach ($link in $links) {
        $fileUrl = $URL + $link.href
        $fileName = [System.IO.Path]::GetFileName($link.href)
        $filePath = Join-Path -Path $Destination -ChildPath $fileName

        Write-Host "Téléchargement de : $fileName..."

        try {
            Invoke-WebRequest -Uri $fileUrl -OutFile $filePath
            Write-Host "Fichier téléchargé : $fileName" -ForegroundColor Green
        } catch {
            Write-Host "Erreur lors du téléchargement de : $fileName" -ForegroundColor Red
        }
    }

    Write-Host "Téléchargement terminé !" -ForegroundColor Cyan
}

# Function to install an application
function Install-Application {
    param ([string]$AppName)

    $AppURL = "$WebShareURL$AppName/"
    $AppDownloadPath = Join-Path -Path $DownloadBasePath -ChildPath $AppName

    # Download all files for the application
    Write-Host "Downloading all files for: $AppName"
    Download-Folder -URL $AppURL -Destination $AppDownloadPath

    # Execute installation scripts if found
    $InstallScripts = Get-ChildItem -Path $AppDownloadPath -Filter "install.*"
    if ($InstallScripts) {
        foreach ($Script in $InstallScripts) {
            Write-Host "Running: $($Script.FullName)"
            switch ($Script.Extension) {
                ".bat" { Start-Process -FilePath $Script.FullName -Wait -NoNewWindow }
                ".cmd" { Start-Process -FilePath $Script.FullName -Wait -NoNewWindow }
                ".ps1" { Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$($Script.FullName)`"" -Wait -NoNewWindow }
            }
        }
    } else {
        Write-Warning "No installation script found for $AppName"
    }
}  

# Function to uninstall an application
function Uninstall-Application {
    param ([string]$AppName)

    $AppURL = "$WebShareURL$AppName/"
    $AppDownloadPath = Join-Path -Path $DownloadBasePath -ChildPath $AppName

    # Download only uninstall scripts
    Write-Host "Downloading uninstall scripts for: $AppName"
    Download-Folder -URL $AppURL -Destination $AppDownloadPath

    # Execute uninstall scripts if found
    $UninstallScripts = Get-ChildItem -Path $AppDownloadPath -Filter "uninstall.*"
    if ($UninstallScripts) {
        foreach ($Script in $UninstallScripts) {
            Write-Host "Running: $($Script.FullName)"
            switch ($Script.Extension) {
                ".bat" { Start-Process -FilePath $Script.FullName -Wait -NoNewWindow }
                ".cmd" { Start-Process -FilePath $Script.FullName -Wait -NoNewWindow }
                ".ps1" { Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$($Script.FullName)`"" -Wait -NoNewWindow }
            }
        }
    } else {
        Write-Warning "No uninstall script found for $AppName"
    }
}  

Write-Host "Disabling indexing on drive C"
Get-WmiObject Win32_Volume -Filter "DriveLetter='C:'" | Set-WmiInstance -Arguments @{IndexingEnabled=$false}

Write-Host "Enabling High Performance power plan"
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

Write-Host "Disabling animations and visual effects"
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Name 'VisualFXSetting' -Value 2

Write-Host "Disabling hibernation"
powercfg -h off

Write-Host "Disabling System Restore"
Disable-ComputerRestore -Drive "C:\"

Write-Host "Applying changes"
gpupdate /force


# Execute installations
foreach ($app in $InstallOptionList) {
    Install-Application $app
}

# Execute uninstallations
foreach ($app in $UninstallOptionList) {
    Uninstall-Application $app
}

Write-Host "Disable unnecessary services"
$VMServicesToDisable = @("SysMain", "DiagTrack", "dmwappushservice", "WSearch", "RetailDemo")
foreach ($service in $VMServicesToDisable) {
    Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
    Set-Service -Name $service -StartupType Disabled
}


