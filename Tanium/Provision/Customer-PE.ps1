$webserviceUrl = "http://epm2024.monlab.lan:12176/GetName"

# Function to log messages
function Log-Message {
    param (
        [string]$message
    )
    # Only remove colons from the timestamp, not from file paths or URLs
    $timestamp = Get-Date -Format "yyyy-MM-dd HHmmss"  # Correct timestamp format without colons
    $logMessage = "$timestamp - $message"
    Add-Content -Path $logFilePath -Value $logMessage
}

if (Test-Path -Path "C:\") {  
    if (-not (Test-Path -Path "C:\Systools"))        { New-Item -Path "C:\Systools" -ItemType Directory } 
    if (-not (Test-Path -Path "C:\Systools\OptLog")) { New-Item -Path "C:\Systools\OptLog" -ItemType Directory }
}
$logFilePath = "C:\Systools\OptLog\provision.log"
Log-Message "Customer-PE Script started."

Import-Module C:\_T\TaniumOSD
Import-Module C:\_T\TaniumClient
$setkeyboard = Get-OSDVariable -Name "setkeyboard"
Log-Message "setkeyboard $setkeyboard"


# Obtain all network interfaces with their MAC addresses
$macAddresses = Get-WmiObject Win32_NetworkAdapter | Where-Object { $_.NetConnectionStatus -eq 2 } | Select-Object -ExpandProperty MACAddress
$macAddresses = $macAddresses -replace "[:\-]", ""
Log-Message "MAC Addresses: $macAddresses"
$urlws = $webserviceUrl+"?macaddress=$macAddresses"
Log-Message "Webservice URL: $urlws"

# Log available drives
$availableDrives = Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Root
Log-Message "Available Drives: $($availableDrives -join ', ')"

# Define paths to check for unattend.xml
$unattendPaths = @(
    "Windows\Panther\unattend.xml",
    "_T\unattend.xml",
    "Windows\Panther\Unattend\unattend.xml"
)




foreach ($drive in $availableDrives) {
    foreach ($relativePath in $unattendPaths) {
        # Construct the full path to the unattend.xml file in the current drive
        $xmlFilePath = Join-Path -Path $drive -ChildPath $relativePath
        Log-Message "Checking for unattend.xml at $xmlFilePath"

        # Ensure the XML file exists before proceeding
        if (Test-Path $xmlFilePath) {
            Log-Message "unattend.xml file found at $xmlFilePath."

            try {
                # Load the XML file
                [xml]$xmlDoc = Get-Content $xmlFilePath

                # Define the namespace manager
                $ns = New-Object System.Xml.XmlNamespaceManager($xmlDoc.NameTable)
                $ns.AddNamespace("ns", "urn:schemas-microsoft-com:unattend")

                # Call the webservice
                $response = Invoke-RestMethod -Uri $urlws
                if ($response.Computername) {
                    Log-Message "Response received from server for MAC $macAddresses - Computername = $($response.Computername), postype = $($response.postype)"

                    # Attempt to find and modify the ComputerName element
                    $computerNameNode = $xmlDoc.SelectSingleNode("//ns:settings[@pass='specialize']/ns:component/ns:ComputerName", $ns)
                    if ($computerNameNode -ne $null) {
                        $computerNameNode.InnerText = $response.Computername
                        # Save the modified XML file
                        $xmlDoc.Save($xmlFilePath)
                        Log-Message "The ComputerName in unattend.xml has been updated to $($response.Computername)"
                    } else {
                        Log-Message "No ComputerName element found in XML."
                    }
                } else {
                    Log-Message "No valid computer found for MAC $macAddresses"
                }
            } catch {
                Log-Message "Error processing unattend.xml at $xmlFilePath - $_"
            }
        } else {
            Log-Message "The unattend.xml file does not exist at $xmlFilePath."
        }
    }
}

Log-Message "Script completed."
