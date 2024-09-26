Function Get-PendingReboot {
	$isReboot = $False
	if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") { $isReboot = $True }
	if (Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations")       { $isReboot = $True }
	if (Test-Path "HKLM:\SOFTWARE\WOW6432Node\LANDesk\managementsuite\WinClient\VulscanReboot")               { $isReboot = $True }
	if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending")  { $isReboot = $True }
	Return $isReboot
}

# ******************** Encrypt Volume ***************************
if (((Get-tpm).TpmReady -eq $True) -and (Get-PendingReboot -eq $false)) {
	# ******************* C drive *******************************
	# Encrypt volume C
	If ($StateC -eq "FullyDecrypted") {
		Write-host "Enable Bitlocker on C Drive"
		add-bitlockerKeyProtector -mountPoint "C:" -TpmProtector
		Enable-BitLocker -mountPoint "C:" -EncryptionMethod XtsAes128 -RecoveryPasswordProtector -SkipHardwareTest -ErrorAction SilentlyContinue
	}	
}
