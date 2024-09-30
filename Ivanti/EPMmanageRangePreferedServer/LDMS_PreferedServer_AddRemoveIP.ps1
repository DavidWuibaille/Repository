#---------------------------------------------------------------------------
$dataSource = "sql.leblogosd.lan"
$user = "sa"
$PassSQL = 'Password1'
$database = "EPM2021"
#---------------------------------------------------------------------------

$connectionString = "Server=$dataSource;uid=$user; pwd=$PassSQL;Database=$database;Integrated Security=False;"
$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connectionString
$connection.Open()

$query = "SELECT * FROM [$database].[dbo].[PreferredServer]"
$command = $connection.CreateCommand()
$command.CommandText = $query
$result = $command.ExecuteReader()
$tablePS2 = new-object System.Data.DataTable
$tablePS2.Load($result)

$query = "SELECT * FROM [$database].[dbo].[PreferredServerIPLimit]"
$command = $connection.CreateCommand()
$command.CommandText = $query
$result = $command.ExecuteReader()
$tableIP2 = new-object System.Data.DataTable
$tableIP2.Load($result)



Function ConvertIP3Digit {
    param(
        [string] $AddIP
    )
	
	$Temp = $AddIP.split(".")
	if ($Temp[0].Length -eq 1) { $Temp[0] = "00" + $Temp[0] }
	if ($Temp[0].Length -eq 2) { $Temp[0] = "0"  + $Temp[0] }
	if ($Temp[1].Length -eq 1) { $Temp[1] = "00" + $Temp[1] }
	if ($Temp[1].Length -eq 2) { $Temp[1] = "0"  + $Temp[1] }
	if ($Temp[2].Length -eq 1) { $Temp[2] = "00" + $Temp[2] }
	if ($Temp[2].Length -eq 2) { $Temp[2] = "0"  + $Temp[2] }
	if ($Temp[3].Length -eq 1) { $Temp[3] = "00" + $Temp[3] }
	if ($Temp[3].Length -eq 2) { $Temp[3] = "0"  + $Temp[3] }
	$AddIP = $Temp[0]+"."+$Temp[1]+"."+$Temp[2]+"."+$Temp[3]
	
	Return $AddIP
}

Function AddIP {
    param(
        [string] $NamePreferedServer,
		[string] $IPadressStart,
		[string] $IPadressEnd
    )	

	$IPadressStart = ConvertIP3Digit -AddIP $IPadressStart
	$IPadressEnd   = ConvertIP3Digit -AddIP $IPadressEnd
	
	#Write-host "ADD $IPadressStart to $IPadressEnd"
		
	foreach ($elementPS2 in $tablePS2) {
		$PreferredServer_Idn_PS2 = $elementPS2.PreferredServer_Idn
		$ServerName2             = $elementPS2.ServerName
		
		if($NamePreferedServer -eq $ServerName2) {
			#Write-host $ServerName2
			$dejaexistant = 0
			foreach ($elementIP2 in $tableIP2) {
				$PreferredServer_Idn_IP2 = $elementIP2.PreferredServer_Idn
				$StartingIPAddress2      = $elementIP2.StartingIPAddress
				$EndingIPAddress2        = $elementIP2.EndingIPAddress
				if ($PreferredServer_Idn_IP2 -eq $PreferredServer_Idn_PS2) {
					#Write-host "$StartingIPAddress2 => $EndingIPAddress2"
					if (($IPadressStart -eq $StartingIPAddress2) -and ($IPadressStart -eq $StartingIPAddress2)) { $dejaexistant = 1 }
				}
			}
			if ($dejaexistant -eq 0) {
				$PreferredServer_Idn_PS2    = ''''+$PreferredServer_Idn_PS2+''''
				$IPadressStart      		= ''''+$IPadressStart+''''
				$IPadressEnd       			= ''''+$IPadressEnd+''''
				write-host "INSERT INTO dbo.PreferredServerIPLimit (PreferredServer_Idn,StartingIPAddress,EndingIPAddress) VALUES ($PreferredServer_Idn_PS2,$IPadressStart,$IPadressEnd);"
			}
		}
	}
}	

Function RemoveIP {
    param(
        [string] $NamePreferedServer,
		[string] $IPadressStart,
		[string] $IPadressEnd
    )	

	$IPadressStart = ConvertIP3Digit -AddIP $IPadressStart
	$IPadressEnd   = ConvertIP3Digit -AddIP $IPadressEnd
	
	#Write-host "ADD $IPadressStart to $IPadressEnd"
		
	foreach ($elementPS2 in $tablePS2) {
		$PreferredServer_Idn_PS2 = $elementPS2.PreferredServer_Idn
		$ServerName2             = $elementPS2.ServerName
		
		if($NamePreferedServer -eq $ServerName2) {
			#Write-host $ServerName2
			$dejaexistant = 0
			foreach ($elementIP2 in $tableIP2) {
				$PreferredServer_Idn_IP2 	= $elementIP2.PreferredServer_Idn
				$PreferredServerIPLimit_Idn = $elementIP2.PreferredServerIPLimit_Idn
				$StartingIPAddress2      	= $elementIP2.StartingIPAddress
				$EndingIPAddress2        	= $elementIP2.EndingIPAddress
				if ($PreferredServer_Idn_IP2 -eq $PreferredServer_Idn_PS2) {
					#Write-host "$StartingIPAddress2 => $EndingIPAddress2"
					if (($IPadressStart -eq $StartingIPAddress2) -and ($IPadressStart -eq $StartingIPAddress2)) { 
						write-host "DELETE FROM dbo.PreferredServerIPLimit WHERE PreferredServerIPLimit_Idn = $PreferredServerIPLimit_Idn"
					}
				}
			}

		}
	}
}	

Function RemoveAllIP {
    param(
        [string] $NamePreferedServer
    )	
		
	foreach ($elementPS2 in $tablePS2) {
		$PreferredServer_Idn_PS2 = $elementPS2.PreferredServer_Idn
		$ServerName2             = $elementPS2.ServerName
		
		if($NamePreferedServer -eq $ServerName2) {
			#Write-host $ServerName2
			$dejaexistant = 0
			foreach ($elementIP2 in $tableIP2) {
				$PreferredServer_Idn_IP2 	= $elementIP2.PreferredServer_Idn
				$PreferredServerIPLimit_Idn = $elementIP2.PreferredServerIPLimit_Idn
				$StartingIPAddress2      	= $elementIP2.StartingIPAddress
				$EndingIPAddress2        	= $elementIP2.EndingIPAddress
				if ($PreferredServer_Idn_IP2 -eq $PreferredServer_Idn_PS2) {
					#Write-host "$StartingIPAddress2 => $EndingIPAddress2"
					
					write-host "DELETE FROM dbo.PreferredServerIPLimit WHERE PreferredServerIPLimit_Idn = $PreferredServerIPLimit_Idn"

				}
			}

		}
	}
}



RemoveAllIP -NamePreferedServer "epm2021.leblogosd.lan"
AddIP -NamePreferedServer "sss" -IPadressStart "192.168.0.1" -IPadressEnd "192.168.0.254" 
RemoveIP -NamePreferedServer "sss" -IPadressStart "192.168.0.1" -IPadressEnd "192.168.0.254" 
