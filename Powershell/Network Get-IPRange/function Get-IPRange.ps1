function Get-IPRange {
    param (
        [string]$gateway,
        [string]$subnetMask
    )
 
    # Check if the gateway and subnet mask are valid
    try {
        $ipAddress = [System.Net.IPAddress]Parse($gateway)
        $ipMask = [System.Net.IPAddress]Parse($subnetMask)
    } catch {
        Write-Warning Invalid IP Address or Subnet Mask Gateway = $gateway, MASK_KS = $subnetMask
        return $null, $null
    }
 
    # Convert IP addresses and mask to bytes and reverse for conversion to UInt32
    $ipBytes = $ipAddress.GetAddressBytes()
    $maskBytes = $ipMask.GetAddressBytes()
 
    # Reverse the bytes to match the little-endian order expected by BitConverter
    [Array]Reverse($ipBytes)
    [Array]Reverse($maskBytes)
 
    # Convert the byte arrays to integers
    $ipAddressInt = [BitConverter]ToUInt32($ipBytes, 0)
    $maskInt = [BitConverter]ToUInt32($maskBytes, 0)
 
    # Calculate the network address and broadcast address
    $networkInt = $ipAddressInt -band $maskInt
    $broadcastInt = $networkInt -bor (-bnot $maskInt)
 
    # Calculate the start address (first host) and end address (last host)
    $startAddressInt = $networkInt + 1
    $endAddressInt = $broadcastInt - 1
 
    # Convert integers back to IP address format
    $startAddressBytes = [BitConverter]GetBytes($startAddressInt)
    $endAddressBytes = [BitConverter]GetBytes($endAddressInt)
 
    # Reverse the bytes again to match the expected IP address format
    [Array]Reverse($startAddressBytes)
    [Array]Reverse($endAddressBytes)
 
    # Convert byte arrays to IP address strings
    $startAddress = [System.Net.IPAddress]Parse(($startAddressBytes -join '.'))
    $endAddress = [System.Net.IPAddress]Parse(($endAddressBytes -join '.'))
 
    return $startAddress, $endAddress
}

# Example values for Gateway and Subnet Mask
$gateway = "192.168.1.1"       # Example Gateway address
$subnetMask = "255.255.255.0"  # Example Subnet Mask
 
# Call the Get-IPRange function with the example values
$startAddress, $endAddress = Get-IPRange -gateway $gateway -subnetMask $subnetMask
 
# Output the results to the console
Write-Host "Start Address (Host Min): $($startAddress.ToString())"
Write-Host "End Address (Host Max): $($endAddress.ToString())"