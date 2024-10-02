$NomSrv = $env:computername
$GetVM = Get-VM

Foreach ($vm in $GetVM) {
	$NameVM = $VM.name
	$Etat   = $VM.State
	
	if (test-path "c:\export") { Remove-item "c:\export" -force -recurse }
	New-Item -Path "c:\export" -ItemType Directory

	Get-VMSnapshot -VMName $NameVM | Remove-VMSnapshot		
	Stop-VM -Name $NameVM
	Export-VM -name $NameVM -Path "c:\export"
	if ($Etat -ne "Off") { Start-VM -Name $NameVM }
	robocopy "c:\export\$NameVM" "\\nas\Backup\HYPERV\$NameVM" /MIR
	if (test-path "c:\export\$NameVM") { Remove-item "c:\export\$NameVM" -force -recurse }
}