$webserviceUrl = "http://epm2024.monlab.lan:12176/GetName"

# Function to log messages
function Log-Message {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $message"
    Add-Content -Path $logFilePath -Value $logMessage
}




if (Test-Path -Path "C:\") {  
    if (-not (Test-Path -Path "C:\Systools"))        { New-Item -Path "C:\Systools" -ItemType Directory } 
    if (-not (Test-Path -Path "C:\Systools\OptLog")) { New-Item -Path "C:\Systools\OptLog" -ItemType Directory }
}
$logFilePath = "C:\Systools\OptLog\provision.log"
Log-Message "Customer Script started."

Import-Module C:\_T\TaniumOSD
Import-Module C:\_T\TaniumClient
$setkeyboard = Get-OSDVariable -Name "setkeyboard"
Log-Message "setkeyboard $setkeyboard"

# Obtain all network interfaces with their MAC addresses
$macAddresses = Get-WmiObject Win32_NetworkAdapter | Where-Object { $_.NetConnectionStatus -eq 2 } | Select-Object -ExpandProperty MACAddress
$macAddresses = $macAddresses.replace(":","")
$macAddresses = $macAddresses.replace("-","")
Log-Message "MAC Addresses: $macAddresses"
$urlws = $webserviceUrl + "?macaddress=$macAddresses"
Log-Message $urlws 

$EnvValue= ""
try {
	$response = Invoke-RestMethod -Uri $urlws
	# Check if the response contains the ComputerName
	if ($response.Computername) {
		Log-Message "Response received from server for MAC $macAddresses : postype = $($response.postype)"
		$EnvValue = $($response.postype)
	} else {
		Log-Message "No valid computer found for MAC $macAddresses"
	}
} catch {
	Log-Message "Error contacting webservice for MAC $macAddresses : $_"
}



Set-OSDProgressDisplay -Message "Apps chrome Download"
# Define the URL and the destination path
$url = "https://nas.wuibaille.fr/partageMyFile789456123/Tanium/GoogleChromeStandaloneEnterprise64.msi"
$destination = "C:\Windows\Temp\GoogleChromeStandaloneEnterprise64.msi"

# Log the start of the process
Log-Message "Starting download from $url"

# Download the file
try {
    Invoke-WebRequest -Uri $url -OutFile $destination
    Log-Message "Download successful"
} catch {
    Log-Message "Download failed: $_"
    exit 1
}

Set-OSDProgressDisplay -Message "Apps chrome Install"
Log-Message "Starting installation of $destination"

# Install the MSI package
try {
    Start-Process "msiexec.exe" -ArgumentList "/i $destination /quiet /norestart" -Wait -NoNewWindow
    Log-Message "Installation successful"
} catch {
    Log-Message "Installation failed: $_"
    exit 1
}

# Log completion of the script
Log-Message "Script execution completed"



# Set the environment variable POSTYPE persistently for the System
[Environment]::SetEnvironmentVariable("POSTYPE", $EnvValue, [EnvironmentVariableTarget]::Machine)


# Define source and destination paths
$sourcePath = "C:\_T"
$destinationPath = "C:\BackupT"

# Log the start of the copy process
Log-Message "Starting copy from $sourcePath to $destinationPath"

try {
    # Check if the destination directory exists, if not, create it
    if (-not (Test-Path -Path $destinationPath)) {
        New-Item -Path $destinationPath -ItemType Directory
        Log-Message "Created directory $destinationPath"
    }

    # Copy all content from source to destination
    Copy-Item -Path $sourcePath\* -Destination $destinationPath -Recurse -Force
    Log-Message "Copy successful from $sourcePath to $destinationPath"
} catch {
    Log-Message "Copy failed: $_"
}

# Log completion of the copy process
Log-Message "Copy process completed"


Log-Message "Script ended."



