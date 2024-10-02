$BiosInfo = Get-WmiObject -Namespace root/hp/instrumentedBIOS -Class hp_biosEnumeration
$BiosSetup = Get-WmiObject -class hp_biossettinginterface -Namespace root\hp\instrumentedbios
foreach ($Conf in $BiosInfo) {
	$Param  = $conf.Name
	$Valeur = $Conf.Value
	
	If ($Param -eq 'Virtualization Technology (VTx)') {
		Write-host $Param	$Valeur				
		$BiosSetup.SetBIOSSetting('Virtualization Technology (VTx)','Enable')
	}
	If ($Param -eq 'Virtualization Technology for Directed I/O (VTd)') 	{
		Write-host $Param	$Valeur
		$BiosSetup.SetBIOSSetting('Virtualization Technology for Directed I/O (VTd)','Enable')
	}
}

