

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

Function Enable-TPM_HP {
  $BiosInfo  = Get-WmiObject -Namespace root/hp/instrumentedBIOS -Class hp_biosEnumeration
  $BiosSetup = Get-WmiObject -Namespace root/hp/instrumentedBIOS -class hp_biossettinginterface

	foreach ($Conf in $BiosInfo) {
		$Param = $conf.Name
		If ($Param -like "*TPM Device*") {
			Write-host "$Param"
			$BiosSetup.SetBIOSSetting($Param,'Enable')
		}
	}
}

Function Test-UEFI {

        <#
        .Synopsis
           Determines underlying firmware (BIOS) type and returns True for UEFI or False for legacy BIOS.
        .DESCRIPTION
           This function uses a complied Win32 API call to determine the underlying system firmware type.
        .EXAMPLE
           If (IsUEFI) { # System is running UEFI firmware... }
        .OUTPUTS
           [Bool] True = UEFI Firmware; False = Legacy BIOS
        .FUNCTIONALITY
           Determines underlying system firmware type
        #>

        [OutputType([Bool])]
        Param ()

Add-Type -Language CSharp -TypeDefinition @'

    using System;
    using System.Runtime.InteropServices;

    public class CheckUEFI
    {
        [DllImport("kernel32.dll", SetLastError=true)]
        static extern UInt32 
        GetFirmwareEnvironmentVariableA(string lpName, string lpGuid, IntPtr pBuffer, UInt32 nSize);

        const int ERROR_INVALID_FUNCTION = 1; 

        public static bool IsUEFI()
        {
            // Try to call the GetFirmwareEnvironmentVariable API.  This is invalid on legacy BIOS.

            GetFirmwareEnvironmentVariableA("","{00000000-0000-0000-0000-000000000000}",IntPtr.Zero,0);

            if (Marshal.GetLastWin32Error() == ERROR_INVALID_FUNCTION)

                return false;     // API not supported; this is a legacy BIOS

            else

                return true;      // API error (expected) but call is supported.  This is UEFI.
        }
    }
'@


    [CheckUEFI]::IsUEFI()
}



Function Get-IsLaptop {
    $isLaptop = $false
    if(Get-WmiObject -Class win32_systemenclosure | Where-Object { $_.chassistypes -eq 8 -or $_.chassistypes -eq 9 -or $_.chassistypes -eq 10 -or $_.chassistypes -eq 14 -or $_.chassistypes -eq 30}) { $isLaptop = $true }
    Return $isLaptop
}

Function Get-PendingReboot {
	$isReboot = $False
	if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") { $isReboot = $True }
	if (Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations")       { $isReboot = $True }
	if (Test-Path "HKLM:\SOFTWARE\WOW6432Node\LANDesk\managementsuite\WinClient\VulscanReboot")               { $isReboot = $True }
	if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending")  { $isReboot = $True }
	Return $isReboot
}


# Exit Code 
# 20200 => Puce TPM

# ******************** Get Info ***************************
write-host "----- Get TPM bios info"
$Manufacturer = (Get-WmiObject -Class Win32_ComputerSystem).Manufacturer
if ((Get-tpm).TpmReady -eq $False) {
	write-host "---------- TPM Off"
	If ($Manufacturer -like "*Dell*") { Enable-TPM_Dell } 
	If ($Manufacturer -like "*HP*")   { Enable-TPM_HP   } 
} Else { write-host "---------- TPM On"}
if ((Get-tpm).TpmReady -eq $False) { 
	Write-Error "Puce TPM not enable ..."
	exit 20200
}

# ******************** Get Info ***************************
write-host "----- Get bitlocker info"
$StateC = (Get-BitLockerVolume -MountPoint "C:").VolumeStatus
If (test-path "D:") { $StateD = (Get-BitLockerVolume -MountPoint "D:").VolumeStatus } Else { $StateD = "NotExist" }
write-host "---------- C: $StateC"
write-host "---------- D: $StateD"

# ******************** Get Info ***************************
write-host "----- Get pendingRebbot"
If (Get-PendingReboot -eq $false) { 
	write-host "---------- OK"
} Else { 
	Write-Error "Reboot Pending"
}

# ******************** Get Info ***************************
write-host "----- Get UEFI"
If (Test-UEFI -eq $True) { 
	write-host "---------- OK"
} Else { 
	Write-Error "Legacy mode enabled"
}



# ******************** Wait or Not Encrypt **********************
If (test-path "d:") {
	# il faut attendre le cryptage du C pour initialisr le cryptage du D
	$NeedWait = $true
} ELse {
	$NeedWait = $false
}


# ******************** Encrypt Volume ***************************
if (((Get-tpm).TpmReady -eq $True) -and (Test-UEFI -eq $True) -and (Get-PendingReboot -eq $false)) {
	# ******************* C drive *******************************
	# Encrypt volume C
	If ($StateC -eq "FullyDecrypted") {
		Write-host "Enable Bitlocker on C Drive"
		add-bitlockerKeyProtector -mountPoint "C:" -TpmProtector
		Enable-BitLocker -mountPoint "C:" -EncryptionMethod XtsAes128 -RecoveryPasswordProtector -SkipHardwareTest -ErrorAction SilentlyContinue
	}	
	# Vait Encrypt finalize
	if ($StateC -ne "FullyEncrypted") { Start-Sleep -Seconds 10 }
	
	# Si j'ai un D il faut que le cryptage du c soit Finalisé
	$Loop = $NeedWait
	while($Loop){
		$StateC = (Get-BitLockerVolume -MountPoint "C:").VolumeStatus
		if ($StateC -eq "FullyEncrypted") { 
			$Loop = $false 
		} Else {
			Write-host "Wait bitlocker in progress"
			Start-Sleep -Seconds 10
		}
	}
	# Force Backup Key in AD
	Write-host "Backup Key in AD"
	$BLV = Get-BitLockerVolume   -MountPoint "C:"
	Backup-BitLockerKeyProtector -MountPoint "C:" -KeyProtectorId $BLV.KeyProtector[1].KeyProtectorId


	# ******************* D drive *******************************
	If (test-path "D:") { 
		$StateC = (Get-BitLockerVolume -MountPoint "C:").VolumeStatus
		$StateD = (Get-BitLockerVolume -MountPoint "D:").VolumeStatus
		
		# C need is fully encrypted for start encrypt volume D
		if (($StateC -eq "FullyEncrypted") -and ($StateD -ne "FullyEncrypted")) { 
			Write-host "Enable Bitlocker on D Drive"
            Add-bitlockerKeyProtector  -mountPoint "d:" -RecoveryPasswordProtector
            Enable-BitLocker           -mountPoint "d:" -EncryptionMethod XtsAes128 -RecoveryPasswordProtector -SkipHardwareTest
            Enable-BitLockerAutoUnlock -MountPoint "d:" 
			
			# Vait Encrypt finalize
			if ($StateD -ne "FullyEncrypted") { Start-Sleep -Seconds 10 }
			$Loop = $NeedWait
			while($Loop){
				$StateD = (Get-BitLockerVolume -MountPoint "D:").VolumeStatus
				if ($StateD -eq "FullyEncrypted") { 
					$Loop = $false 
				} Else {
					Write-host "Wait bitlocker in progress"
					Start-Sleep -Seconds 10
				}
			}	
		
		}	
	}
}

