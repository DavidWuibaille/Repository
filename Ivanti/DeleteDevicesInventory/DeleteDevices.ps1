# http://localhost/MBSDKService/MsgSDK.asmx?WSDL/GetMachineData

#------------------ Change 
#------ $ListDeviceCSVs Change file csv name (Pas de nom de colonne dans le csv)
#------ $ldWS Change ldms core server name


DEV $mycreds = Get-Credential -Credential "Leblogosd\david"
DEV $ldWS    = New-WebServiceProxy -uri http://EPM2021/MBSDKService/MsgSDK.asmx?WSDL -Credential $mycreds
$ListDevices = $ldWS.ListMachines("").Devices

$ListDeviceCSVs = Import-Csv "C:\Scripts\DeleteDevicesInventory\DeviceNeedDelete.csv" -Delimiter ";" -Header Name

#GUID                                   DeviceName      DomainName           LastLogin
foreach ($ListDevice in $ListDevices) {
	$DeviceLDMSName = $ListDevice.DeviceName
	$DeviceLDMSGUID = $ListDevice.GUID
	ForEach ($ListDeviceCSV in $ListDeviceCSVs){
		$Computer = $ListDeviceCSV.Name
		if ($DeviceLDMSName -eq $Computer) {
			write-host $Computer
			$ldWS.DeleteComputerByGUID($DeviceLDMSGUID)
		}
	}
}


