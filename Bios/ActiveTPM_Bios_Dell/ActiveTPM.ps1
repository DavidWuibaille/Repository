

Function Enable-TPM_Dell {
	param(
        [string] $BiosPassword = ""
    )	
	
	$DellModulePath = "${env:ProgramFiles}\WindowsPowerShell\Modules\DellBIOSProvider"
	if (test-path $DellModulePath) {
		write-host "PASS"
		import-module DellBIOSProvider
		If ($BiosPassword -eq "") { 
			Set-Item -Path DellSmbios:\TpmSecurity\TpmSecurity "Enabled"
		} Else {
			Set-Item -Path DellSmbios:\TpmSecurity\TpmSecurity "Enabled" -Password $BiosPassword
		}
	} Else {
		Write-Error "DellBIOSProvider Module Not Exist..."
	}
}


Enable-TPM_Dell