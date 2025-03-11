# Verify script runs with admin rights
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole] "Administrator")) {
    Write-Error "This script must be run as Administrator!"
    exit
}

# Configuration options
$ServiceStopOption  = "Tanium"     # Services to disable and stop (e.g. "Tanium,Ivanti")
$ServiceStartOption = "Ivanti"     # Services to enable and start
$InstallOption      = "Chrome,7Zip" # Applications to install ("Chrome", "7Zip", "Chrome,7Zip" or "")

# Convert options to lists
$ServiceStopList  = $ServiceStopOption -split ',' | ForEach-Object { $_.Trim().ToLower() }
$ServiceStartList = $ServiceStartOption -split ',' | ForEach-Object { $_.Trim().ToLower() }
$InstallOptionList = $InstallOption -split ',' | ForEach-Object { $_.Trim().ToLower() }

# Function to disable and stop service
function Disable-ServiceByName($ServiceName) {
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($service) {
        Write-Host "Disabling and stopping $ServiceName..."
        Set-Service -Name $ServiceName -StartupType Disabled
        Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
        Write-Host "$ServiceName disabled and stopped."
    } else {
        Write-Warning "$ServiceName service not found."
    }
}

# Function to enable and start service
function Enable-ServiceByName($ServiceName) {
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($service) {
        Write-Host "Enabling and starting $ServiceName..."
        Set-Service -Name $ServiceName -StartupType Automatic
        Start-Service -Name $ServiceName -ErrorAction SilentlyContinue
        Write-Host "$ServiceName enabled and started."
    } else {
        Write-Warning "$ServiceName service not found."
    }
}

# Check for winget installation
if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Warning "Winget is not installed. Application installations will be skipped."
    $InstallOptionList = @()
}

# Function to install applications
function Install-Application($AppName) {
    switch ($AppName) {
        "chrome" {
            Write-Host "Installing Google Chrome..."
            winget install --id Google.Chrome --silent --accept-package-agreements --accept-source-agreements
            Write-Host "Google Chrome installed."
        }
        "7zip" {
            Write-Host "Installing 7-Zip..."
            winget install --id 7zip.7zip --silent --accept-package-agreements --accept-source-agreements
            Write-Host "7-Zip installed."
        }
        Default {
            Write-Warning "Unknown application: $AppName"
        }
    }
}

# Manage Tanium services
if ($ServiceStopList -contains "tanium") {
    Disable-ServiceByName "Tanium Client"
    Disable-ServiceByName "TaniumDriverSvc"
}
if ($ServiceStartList -contains "tanium") {
    Enable-ServiceByName "Tanium Client"
    Enable-ServiceByName "TaniumDriverSvc"
}

# Manage Ivanti services
$IvantiServices = Get-Service | Where-Object { $_.DisplayName -like "Ivanti*" }
if ($ServiceStopList -contains "ivanti") {
    if ($IvantiServices) {
        foreach ($service in $IvantiServices) { Disable-ServiceByName $service.Name }
    } else { Write-Warning "No Ivanti services found." }
}
if ($ServiceStartList -contains "ivanti") {
    if ($IvantiServices) {
        foreach ($service in $IvantiServices) { Enable-ServiceByName $service.Name }
    } else { Write-Warning "No Ivanti services found." }
}

# Install selected applications
foreach ($app in $InstallOptionList) {
    Install-Application $app
}

# Always apply performance optimizations
Write-Host "Applying performance optimizations..."
powercfg -change -monitor-timeout-ac 0
powercfg -change -standby-timeout-ac 0

# Detect OS type (Client vs Server)
$OSInfo = Get-WmiObject Win32_OperatingSystem
$OSName = $OSInfo.Caption

if ($OSName -match "Windows 10|Windows 11") {
    Write-Host "Client OS detected ($OSName). Applying optimizations..."

    # Disable unnecessary services
    $servicesToDisable = @(
        "SysMain", "DiagTrack", "dmwappushservice",
        "WSearch", "MapsBroker", "RetailDemo"
    )
    foreach ($service in $servicesToDisable) {
        Disable-ServiceByName $service
    }

    # Disable Windows Firewall
    Write-Host "Disabling Windows Firewall..."
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

    # Disable Windows Defender Real-time Protection
    Write-Host "Disabling Windows Defender Real-time Protection..."
    Set-MpPreference -DisableRealtimeMonitoring $true

    # Disable telemetry scheduled tasks
    Write-Host "Disabling telemetry tasks..."
    Get-ScheduledTask -TaskPath "\Microsoft\Windows\Application Experience\" | Disable-ScheduledTask -ErrorAction SilentlyContinue
    Get-ScheduledTask -TaskPath "\Microsoft\Windows\Customer Experience Improvement Program\" | Disable-ScheduledTask -ErrorAction SilentlyContinue

    # Optimize visual effects
    Write-Host "Optimizing visual effects..."
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Name 'VisualFXSetting' -Value 2

    # Set power plan High Performance
    Write-Host "Setting power plan to High Performance..."
    powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

    # Disable hibernation and system restore
    Write-Host "Disabling hibernation and system restore..."
    powercfg -h off
    Disable-ComputerRestore -Drive "C:\"

    # Disable indexing on drive C
    Write-Host "Disabling indexing on drive C..."
    Get-WmiObject Win32_Volume -Filter "DriveLetter='C:'" | Set-WmiInstance -Arguments @{IndexingEnabled=$false}

    # Apply settings immediately
    Write-Host "Applying settings immediately..."
    gpupdate /force
    Write-Host "All configurations applied successfully."
}
else {
    Write-Host "Server OS detected ($OSName). Only basic performance optimizations applied."
}
