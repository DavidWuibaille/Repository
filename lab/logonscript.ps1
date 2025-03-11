# Check if the script is running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole] "Administrator")) {
    Write-Error "This script must be run as Administrator!"
    exit
}

# Configuration options
$InstallOption = "Chrome,7Zip,ClientIVANTI,ClientTanium,ClientSCCM,ClientKACE"  # Applications to install
$UninstallOption = "Chrome"  # Applications to uninstall
$WebShareURL = "https://nas.wuibaille.fr/labo777/DML/"
$DownloadBasePath = "C:\Windows\Temp\DML"

# Convert options into lists
$InstallOptionList = $InstallOption -split ',' | ForEach-Object { $_.Trim().ToLower() }
$UninstallOptionList = $UninstallOption -split ',' | ForEach-Object { $_.Trim().ToLower() }

# 📂 Function to download all files in a web folder recursively
function Download-Folder {
    param (
        [string]$URL,
        [string]$Destination
    )

    # Create destination folder if it does not exist
    if (-not (Test-Path $Destination)) {
        New-Item -ItemType Directory -Path $Destination | Out-Null
    }

    try {
        # Get the HTML content of the folder
        $WebPageContent = Invoke-WebRequest -Uri $URL -UseBasicParsing
    } catch {
        Write-Error "❌ Unable to access URL: $URL"
        return
    }

    # Extract file and folder links
    $Links = $WebPageContent.Links | Where-Object { $_.href -notmatch "^\?" }

    foreach ($Link in $Links) {
        $Href = $Link.href
        $FullURL = "$URL$Href"
        $LocalPath = Join-Path -Path $Destination -ChildPath $Href

        if ($Href -match "/$") {
            # 📂 If it's a folder, call function recursively
            Write-Host "📂 Entering folder: $FullURL"
            Download-Folder -URL $FullURL -Destination $LocalPath
        } elseif ($Href -match "^\w+(\.\w+)+$") {
            # 📥 If it's a file, download it
            Write-Host "📥 Downloading: $FullURL -> $LocalPath"
            try {
                Invoke-WebRequest -Uri $FullURL -OutFile $LocalPath
            } catch {
                Write-Error "❌ Failed to download: $FullURL"
            }
        }
    }
}  # <-- ✅ Closing } for Download-Folder

# 🔽 Function to install an application
function Install-Application {
    param ([string]$AppName)

    $AppURL = "$WebShareURL$AppName/"
    $AppDownloadPath = Join-Path -Path $DownloadBasePath -ChildPath $AppName

    # Download all files for the application
    Write-Host "🔽 Downloading all files for: $AppName"
    Download-Folder -URL $AppURL -Destination $AppDownloadPath

    # Execute installation scripts if found
    $InstallScripts = Get-ChildItem -Path $AppDownloadPath -Filter "install.*"
    if ($InstallScripts) {
        foreach ($Script in $InstallScripts) {
            Write-Host "🚀 Running: $($Script.FullName)"
            switch ($Script.Extension) {
                ".bat" { Start-Process -FilePath $Script.FullName -Wait -NoNewWindow }
                ".cmd" { Start-Process -FilePath $Script.FullName -Wait -NoNewWindow }
                ".ps1" { Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$($Script.FullName)`"" -Wait -NoNewWindow }
            }
        }
    } else {
        Write-Warning "⚠️ No installation script found for $AppName"
    }
}  # <-- ✅ Closing } for Install-Application

# 🔽 Function to uninstall an application
function Uninstall-Application {
    param ([string]$AppName)

    $AppURL = "$WebShareURL$AppName/"
    $AppDownloadPath = Join-Path -Path $DownloadBasePath -ChildPath $AppName

    # Download only uninstall scripts
    Write-Host "🔽 Downloading uninstall scripts for: $AppName"
    Download-Folder -URL $AppURL -Destination $AppDownloadPath

    # Execute uninstall scripts if found
    $UninstallScripts = Get-ChildItem -Path $AppDownloadPath -Filter "uninstall.*"
    if ($UninstallScripts) {
        foreach ($Script in $UninstallScripts) {
            Write-Host "🚀 Running: $($Script.FullName)"
            switch ($Script.Extension) {
                ".bat" { Start-Process -FilePath $Script.FullName -Wait -NoNewWindow }
                ".cmd" { Start-Process -FilePath $Script.FullName -Wait -NoNewWindow }
                ".ps1" { Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$($Script.FullName)`"" -Wait -NoNewWindow }
            }
        }
    } else {
        Write-Warning "⚠️ No uninstall script found for $AppName"
    }
}  # <-- ✅ Closing } for Uninstall-Application

# 🛠 Execute installations
foreach ($app in $InstallOptionList) {
    Install-Application $app
}

# 🛠 Execute uninstallations
foreach ($app in $UninstallOptionList) {
    Uninstall-Application $app
}

# ✅ Performance optimizations
Write-Host "⚡ Applying performance optimizations..."
powercfg -change -monitor-timeout-ac 0
powercfg -change -standby-timeout-ac 0

Write-Host "✅ All configurations applied successfully."
