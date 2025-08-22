#
#  Copyright 2018-2024 HP Development Company, L.P.
#  All Rights Reserved.
#
# NOTICE:  All information contained herein is, and remains the property of HP Development Company, L.P.
#
# The intellectual and technical concepts contained herein are proprietary to HP Development Company, L.P
# and may be covered by U.S. and Foreign Patents, patents in process, and are protected by
# trade secret or copyright law. Dissemination of this information or reproduction of this material
# is strictly forbidden unless prior written permission is obtained from HP Development Company, L.P.
#
using namespace HP.CMSLHelper

Set-StrictMode -Version 3.0

# CMSL is normally installed in C:\Program Files\WindowsPowerShell\Modules
# but if installed via PSGallery and via PS7, it is installed in a different location
if (Test-Path "$PSScriptRoot\..\HP.Private\HP.CMSLHelper.dll") {
  Add-Type -Path "$PSScriptRoot\..\HP.Private\HP.CMSLHelper.dll"
}
else{
  Add-Type -Path "$PSScriptRoot\..\..\HP.Private\1.7.2\HP.CMSLHelper.dll"
}

[Flags()] enum UEFIVariableAttributes{
  VARIABLE_ATTRIBUTE_NON_VOLATILE = 0x00000001
  VARIABLE_ATTRIBUTE_BOOTSERVICE_ACCESS = 0x00000002
  VARIABLE_ATTRIBUTE_RUNTIME_ACCESS = 0x00000004
  VARIABLE_ATTRIBUTE_HARDWARE_ERROR_RECORD = 0x00000008
  VARIABLE_ATTRIBUTE_AUTHENTICATED_WRITE_ACCESS = 0x00000010
  VARIABLE_ATTRIBUTE_TIME_BASED_AUTHENTICATED_WRITE_ACCESS = 0x00000020
  VARIABLE_ATTRIBUTE_APPEND_WRITE = 0x00000040
}


<#
    .SYNOPSIS
    Retrieves a UEFI variable value

    .DESCRIPTION
    This command retrieves the value of a UEFI variable. 

    .PARAMETER Name
    Specifies the name of the UEFI variable to read

    .PARAMETER Namespace
    Specifies a custom namespace. The namespace must be in the format of a UUID, surrounded by curly brackets.

    .PARAMETER AsString
    If specified, this command will return the value as a string rather than a byte array. Note that the commands in this library support UTF-8 compatible strings. Other applications may store strings that are not compatible with this translation, in which
    case the caller should retrieve the value as an array (default) and post-process it as needed.

    .EXAMPLE
    PS>  Get-HPUEFIVariable -GlobalNamespace -Name MyVariable

    .EXAMPLE
    PS>  Get-HPUEFIVariable -Namespace "{21969aa8-681f-46be-90f0-6019ce9b0ee7}"  -Name MyVariable

    .NOTES
    - The process calling these commands must be able to acquire 'SeSystemEnvironmentPrivilege' privileges for the operation to succeed. For more information, refer to "Modify firmware environment values" in the linked documentation below.
    - This command is not supported on legacy mode, only on UEFI mode.
    - This command requires elevated privileges.

    .OUTPUTS
    This command returns a custom object that contains the variable value and its attributes.

    .LINK
    [UEFI Specification 2.3.1 Section 7.2](https://www.uefi.org/specifications)

    .LINK
    [Modify firmware environment values](https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/modify-firmware-environment-values)
#>
function Get-HPUEFIVariable
{
  [CmdletBinding(DefaultParameterSetName = 'NsCustom',HelpUri = "https://developers.hp.com/hp-client-management/doc/Get-HPUEFIVariable")]
  [Alias("Get-UEFIVariable")]
  param(
    [Parameter(Position = 0,Mandatory = $true,ParameterSetName = "NsCustom")]
    [string]$Name,

    [Parameter(Position = 1,Mandatory = $true,ParameterSetName = "NsCustom")]
    [string]$Namespace,

    [Parameter(Position = 2,Mandatory = $false,ParameterSetName = "NsCustom")]
    [switch]$AsString
  )

  if (-not (Test-IsElevatedAdmin)) {
    throw [System.Security.AccessControl.PrivilegeNotHeldException]"elevated administrator"
  }

  $PreviousState = [PrivilegeState]::Enabled;
  Set-HPPrivateEnablePrivilege -ProcessId $PID -PreviousState ([ref]$PreviousState) -State ([PrivilegeState]::Enabled)

  $size = 1024 # fixed max size
  $result = New-Object Byte[] (1024)
  [uint32]$attr = 0

  Write-Verbose "Querying UEFI variable $Namespace/$Name"
  Get-HPPrivateFirmwareEnvironmentVariableExW -Name $Name -Namespace $Namespace -Result $result -Size $size -Attributes ([ref]$attr)

  $r = [pscustomobject]@{
    Value = ''
    Attributes = [UEFIVariableAttributes]$attr
  }
  if ($asString.IsPresent) {
    $enc = [System.Text.Encoding]::UTF8
    $r.Value = $enc.GetString($result)
  }
  else {
    $r.Value = [array]$result
  }

  if ($PreviousState -eq [PrivilegeState]::Disabled) {
    Set-HPPrivateEnablePrivilege -ProcessId $PID -PreviousState ([ref]$PreviousState) -State ([PrivilegeState]::Disabled)
  }
  $r
}

<#
    .SYNOPSIS
    Sets a UEFI variable value

    .DESCRIPTION
    This command sets the value of a UEFI variable. If the variable does not exist, this command will create the variable. 

    .PARAMETER Name
    Specifies the name of the UEFI variable to update or create

    .PARAMETER Namespace
    Specifies a custom namespace. The namespace must be in the format of a UUID, surrounded by curly brackets.

    .PARAMETER Value
    Specifies the new value for the UEFI variable. Note that a NULL value will delete the variable.

    The value may be a byte array (type byte[],  recommended), or a string which will be converted to UTF8 and stored as a byte array.

    .PARAMETER Attributes
    Specifies the attributes for the UEFI variable. For more information, see the UEFI specification linked below.

    Attributes may be:

    - VARIABLE_ATTRIBUTE_NON_VOLATILE: The firmware environment variable is stored in non-volatile memory (e.g. NVRAM). 
    - VARIABLE_ATTRIBUTE_BOOTSERVICE_ACCESS: The firmware environment variable can be accessed during boot service. 
    - VARIABLE_ATTRIBUTE_RUNTIME_ACCESS:  The firmware environment variable can be accessed at runtime. Note  Variables with this attribute set, must also have VARIABLE_ATTRIBUTE_BOOTSERVICE_ACCESS set. 
    - VARIABLE_ATTRIBUTE_HARDWARE_ERROR_RECORD:  Indicates hardware related errors encountered at runtime. 
    - VARIABLE_ATTRIBUTE_AUTHENTICATED_WRITE_ACCESS: Indicates an authentication requirement that must be met before writing to this firmware environment variable. 
    - VARIABLE_ATTRIBUTE_TIME_BASED_AUTHENTICATED_WRITE_ACCESS: Indicates authentication and time stamp requirements that must be met before writing to this firmware environment variable. When this attribute is set, the buffer, represented by pValue, will begin with an instance of a complete (and serialized) EFI_VARIABLE_AUTHENTICATION_2 descriptor. 
    - VARIABLE_ATTRIBUTE_APPEND_WRITE: Append an existing environment variable with the value of pValue. If the firmware does not support the operation, then SetFirmwareEnvironmentVariableEx will return ERROR_INVALID_FUNCTION.

    .EXAMPLE
    PS>  Set-HPUEFIVariable -Namespace "{21969aa8-681f-46be-90f0-6019ce9b0ee7}" -Name MyVariable -Value 1,2,3

    .EXAMPLE
    PS>  Set-HPUEFIVariable -Namespace "{21969aa8-681f-46be-90f0-6019ce9b0ee7}" -Name MyVariable -Value "ABC"

    .NOTES
    - It is not recommended that the attributes of an existing variable are updated. If new attributes are required, the value should be deleted and re-created.
    - The process calling these commands must be able to acquire 'SeSystemEnvironmentPrivilege' privileges for the operation to succeed. For more information, refer to "Modify firmware environment values" in the linked documentation below.
    - This command is not supported on legacy BIOS mode, only on UEFI mode.
    - This command requires elevated privileges.

    .LINK
    [UEFI Specification 2.3.1 Section 7.2](https://www.uefi.org/specifications)

    .LINK
    [Modify firmware environment values](https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/modify-firmware-environment-values)
#>

function Set-HPUEFIVariable
{
  [CmdletBinding(DefaultParameterSetName = 'NsCustom',HelpUri = "https://developers.hp.com/hp-client-management/doc/Set-HPUEFIVariable")]
  [Alias("Set-UEFIVariable")]
  param(
    [Parameter(Position = 0,Mandatory = $true,ParameterSetName = "NsCustom")]
    [string]$Name,

    [Parameter(Position = 1,Mandatory = $true,ParameterSetName = "NsCustom")]
    $Value,

    [Parameter(Position = 2,Mandatory = $true,ParameterSetName = "NsCustom")]
    [string]$Namespace,

    [Parameter(Position = 3,Mandatory = $false,ParameterSetName = "NsCustom")]
    [UEFIVariableAttributes]$Attributes = 7
  )

  if (-not (Test-IsElevatedAdmin)) {
    throw [System.Security.AccessControl.PrivilegeNotHeldException]"elevated administrator"
  }

  $err = "The Value must be derived from base types 'String' or 'Byte[]' or Byte"

  [byte[]]$rawvalue = switch ($Value.GetType().Name) {
    "String" {
      $enc = [System.Text.Encoding]::UTF8
      $v = @($enc.GetBytes($Value))
      Write-Verbose "String value representation is $v"
      [byte[]]$v
    }
    "Int32" {
      $v = [byte[]]$Value
      Write-Verbose "Byte value representation is $v"
      [byte[]]$v
    }
    "Object[]" {
      try {
        $v = [byte[]]$Value
        Write-Verbose "Byte array value representation is $v"
        [byte[]]$v
      }
      catch {
        throw $err
      }
    }
    default {
      throw "Value type $($Value.GetType().Name): $err" 
    }
  }


  $PreviousState = [PrivilegeState]::Enabled
  Set-HPPrivateEnablePrivilege -ProcessId $PID -PreviousState ([ref]$PreviousState) -State ([PrivilegeState]::Enabled)

  $len = 0
  if ($rawvalue) { $len = $rawvalue.Length }

  if (-not $len -and -not ($Attributes -band [UEFIVariableAttributes]::VARIABLE_ATTRIBUTE_AUTHENTICATED_WRITE_ACCESS -or
      $Attributes -band [UEFIVariableAttributes]::VARIABLE_ATTRIBUTE_TIME_BASED_AUTHENTICATED_WRITE_ACCESS -or
      $Attributes -band [UEFIVariableAttributes]::VARIABLE_ATTRIBUTE_APPEND_WRITE)) {
    # Any attribute different from 0x40, 0x10 and 0x20 combined with a value size of zero removes the UEFI variable.
    # Note that zero is not a valid attribute, see [UEFIVariableAttributes] enum
    Write-Verbose "Deleting UEFI variable $Namespace/$Name"
  }
  else {
    Write-Verbose "Setting UEFI variable $Namespace/$Name to value $rawvalue (length = $len), Attributes $([UEFIVariableAttributes]$Attributes)"
  }

  Set-HPPrivateFirmwareEnvironmentVariableExW -Name $Name -Namespace $Namespace -RawValue $rawvalue -Len $len -Attributes $Attributes

  if ($PreviousState -eq [PrivilegeState]::Disabled) {
    Set-HPPrivateEnablePrivilege -ProcessId $PID -PreviousState ([ref]$PreviousState) -State ([PrivilegeState]::Disabled)
  }
}

function Set-HPPrivateEnablePrivilege
{
  [CmdletBinding()]
  param(
    $ProcessId,
    [ref]$PreviousState,
    $State
  )

  try {
    $enablePrivilege = [Native]::EnablePrivilege($PID,"SeSystemEnvironmentPrivilege",$PreviousState,$State)
  }
  catch {
    $enablePrivilege = -1 # non-zero means error
    Write-Verbose "SeSystemEnvironmentPrivilege failed: $($_.Exception.Message)"
  }

  if ($enablePrivilege -ne 0) {
    $err = [System.ComponentModel.Win32Exception][Runtime.InteropServices.Marshal]::GetLastWin32Error()
    throw [UnauthorizedAccessException]"Current user cannot acquire UEFI variable access permissions: $err ($enablePrivilege)"
  }
  else {
    $newStateStr = if ($State -eq [PrivilegeState]::Enabled) { "Enabling" } else { "Disabling" }
    $prevStateStr = if ($PreviousState.Value -eq [PrivilegeState]::Enabled) { "enabled" } else { "disabled" }
    Write-Verbose "$newStateStr application privilege; it was $prevStateStr before"
  }
}

function Set-HPPrivateFirmwareEnvironmentVariableExW
{
  [CmdletBinding()]
  param(
    $Name,
    $Namespace,
    $RawValue,
    $Len,
    $Attributes
  )

  try {
    $setVariable = [Native]::SetFirmwareEnvironmentVariableExW($Name,$Namespace,$RawValue,$Len,$Attributes)
  }
  catch {
    $setVariable = 0 # zero means error
    Write-Verbose "SetFirmwareEnvironmentVariableExW failed: $($_.Exception.Message)"
  }

  if ($setVariable -eq 0) {
    $err = [System.ComponentModel.Win32Exception][Runtime.InteropServices.Marshal]::GetLastWin32Error();
    throw "Could not write UEFI variable: $err. This function is not supported on legacy BIOS mode, only on UEFI mode.";
  }
}

function Get-HPPrivateFirmwareEnvironmentVariableExW
{
  [CmdletBinding()]
  param(
    $Name,
    $Namespace,
    $Result,
    $Size,
    [ref]$Attributes
  )

  try {
    $getVariable = [Native]::GetFirmwareEnvironmentVariableExW($Name,$Namespace,$Result,$Size,$Attributes)
  }
  catch {
    $getVariable = 0 # zero means error
    Write-Verbose "GetFirmwareEnvironmentVariableExW failed: $($_.Exception.Message)"
  }

  if ($getVariable -eq 0)
  {
    $err = [System.ComponentModel.Win32Exception][Runtime.InteropServices.Marshal]::GetLastWin32Error();
    throw "Could not read UEFI variable: $err. This function is not supported on legacy BIOS mode, only on UEFI mode.";
  }
}

<#
    .SYNOPSIS
    Removes a UEFI variable

    .DESCRIPTION
    This command removes a UEFI variable from a well-known or user-supplied namespace. 

    .PARAMETER Name
    Specifies the name of the UEFI variable to remove

    .PARAMETER Namespace
    Specifies a custom namespace. The namespace must be in the format of a UUID, surrounded by curly brackets.
    
    .EXAMPLE
    PS>  Remove-HPUEFIVariable -Namespace "{21969aa8-681f-46be-90f0-6019ce9b0ee7}" -Name MyVariable

    .NOTES
    - The process calling these commands must be able to acquire 'SeSystemEnvironmentPrivilege' privileges for the operation to succeed. For more information, refer to "Modify firmware environment values" in the linked documentation below.
    - This command is not supported on legacy mode, only on UEFI mode.
    - This command requires elevated privileges.

    .LINK
    [Modify firmware environment values](https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/modify-firmware-environment-values)

#>
function Remove-HPUEFIVariable
{
  [CmdletBinding(DefaultParameterSetName = 'NsCustom',HelpUri = "https://developers.hp.com/hp-client-management/doc/Remove-HPUEFIVariable")]
  [Alias("Remove-UEFIVariable")]
  param(
    [Parameter(Position = 0,Mandatory = $true,ParameterSetName = "NsCustom")]
    [string]$Name,

    [Parameter(Position = 1,Mandatory = $true,ParameterSetName = "NsCustom")]
    [string]$Namespace
  )
  Set-HPUEFIVariable @PSBoundParameters -Value "" -Attributes 7
}

# SIG # Begin signature block
# MIIoHQYJKoZIhvcNAQcCoIIoDjCCKAoCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDzSY1W2TdXSelF
# E1RazxfGjMmBZmh1+v7B7QmOt0oTXKCCDYowggawMIIEmKADAgECAhAIrUCyYNKc
# TJ9ezam9k67ZMA0GCSqGSIb3DQEBDAUAMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNV
# BAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDAeFw0yMTA0MjkwMDAwMDBaFw0z
# NjA0MjgyMzU5NTlaMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2RlIFNpZ25pbmcg
# UlNBNDA5NiBTSEEzODQgMjAyMSBDQTEwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAw
# ggIKAoICAQDVtC9C0CiteLdd1TlZG7GIQvUzjOs9gZdwxbvEhSYwn6SOaNhc9es0
# JAfhS0/TeEP0F9ce2vnS1WcaUk8OoVf8iJnBkcyBAz5NcCRks43iCH00fUyAVxJr
# Q5qZ8sU7H/Lvy0daE6ZMswEgJfMQ04uy+wjwiuCdCcBlp/qYgEk1hz1RGeiQIXhF
# LqGfLOEYwhrMxe6TSXBCMo/7xuoc82VokaJNTIIRSFJo3hC9FFdd6BgTZcV/sk+F
# LEikVoQ11vkunKoAFdE3/hoGlMJ8yOobMubKwvSnowMOdKWvObarYBLj6Na59zHh
# 3K3kGKDYwSNHR7OhD26jq22YBoMbt2pnLdK9RBqSEIGPsDsJ18ebMlrC/2pgVItJ
# wZPt4bRc4G/rJvmM1bL5OBDm6s6R9b7T+2+TYTRcvJNFKIM2KmYoX7BzzosmJQay
# g9Rc9hUZTO1i4F4z8ujo7AqnsAMrkbI2eb73rQgedaZlzLvjSFDzd5Ea/ttQokbI
# YViY9XwCFjyDKK05huzUtw1T0PhH5nUwjewwk3YUpltLXXRhTT8SkXbev1jLchAp
# QfDVxW0mdmgRQRNYmtwmKwH0iU1Z23jPgUo+QEdfyYFQc4UQIyFZYIpkVMHMIRro
# OBl8ZhzNeDhFMJlP/2NPTLuqDQhTQXxYPUez+rbsjDIJAsxsPAxWEQIDAQABo4IB
# WTCCAVUwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQUaDfg67Y7+F8Rhvv+
# YXsIiGX0TkIwHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5nP+e6mK4cD08wDgYDVR0P
# AQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMDMHcGCCsGAQUFBwEBBGswaTAk
# BggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEEGCCsGAQUFBzAC
# hjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9v
# dEc0LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8vY3JsMy5kaWdpY2VydC5j
# b20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAcBgNVHSAEFTATMAcGBWeBDAED
# MAgGBmeBDAEEATANBgkqhkiG9w0BAQwFAAOCAgEAOiNEPY0Idu6PvDqZ01bgAhql
# +Eg08yy25nRm95RysQDKr2wwJxMSnpBEn0v9nqN8JtU3vDpdSG2V1T9J9Ce7FoFF
# UP2cvbaF4HZ+N3HLIvdaqpDP9ZNq4+sg0dVQeYiaiorBtr2hSBh+3NiAGhEZGM1h
# mYFW9snjdufE5BtfQ/g+lP92OT2e1JnPSt0o618moZVYSNUa/tcnP/2Q0XaG3Ryw
# YFzzDaju4ImhvTnhOE7abrs2nfvlIVNaw8rpavGiPttDuDPITzgUkpn13c5Ubdld
# AhQfQDN8A+KVssIhdXNSy0bYxDQcoqVLjc1vdjcshT8azibpGL6QB7BDf5WIIIJw
# 8MzK7/0pNVwfiThV9zeKiwmhywvpMRr/LhlcOXHhvpynCgbWJme3kuZOX956rEnP
# LqR0kq3bPKSchh/jwVYbKyP/j7XqiHtwa+aguv06P0WmxOgWkVKLQcBIhEuWTatE
# QOON8BUozu3xGFYHKi8QxAwIZDwzj64ojDzLj4gLDb879M4ee47vtevLt/B3E+bn
# KD+sEq6lLyJsQfmCXBVmzGwOysWGw/YmMwwHS6DTBwJqakAwSEs0qFEgu60bhQji
# WQ1tygVQK+pKHJ6l/aCnHwZ05/LWUpD9r4VIIflXO7ScA+2GRfS0YW6/aOImYIbq
# yK+p/pQd52MbOoZWeE4wggbSMIIEuqADAgECAhAJvPMqSNxAYhV5FFpsbzOhMA0G
# CSqGSIb3DQEBCwUAMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2RlIFNpZ25pbmcg
# UlNBNDA5NiBTSEEzODQgMjAyMSBDQTEwHhcNMjQwMjE1MDAwMDAwWhcNMjUwMjE4
# MjM1OTU5WjBaMQswCQYDVQQGEwJVUzETMBEGA1UECBMKQ2FsaWZvcm5pYTESMBAG
# A1UEBxMJUGFsbyBBbHRvMRAwDgYDVQQKEwdIUCBJbmMuMRAwDgYDVQQDEwdIUCBJ
# bmMuMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEApbF6fMFy6zhGVra3
# SZN418Cp2O8kjihQCU9tqPO9tkzbMyTsgveLJVnXPJNG9kQPMGUNp+wEHcoUzlRc
# YJMEL9fhfzpWPeSIIezGLPCdrkMmS3fdRUwFqEs7z/C6Ui2ZqMaKhKjBJTIWnipe
# rRfzGB7RoLepQcgqeF5s0DBy4oG83dqcRHo3IJRTBg39tHe3mD5uoGHn5n366abX
# vC+k53BVyD8w8XLppFVH5XuNlXMq/Ohf613i7DRb/+u92ZiAPVPXXnlxUE26cuDb
# OfJKN/bXPmvnWcNW3YHVp9ztPTQZhX4yWYXHrAI2Cv6HxUpO6NzhFoRoBTkcYNbA
# 91pf1Vagh/MNcA2BfQYT975/Vlvj9cfEZ/NwZthZuHa3rdrvCKhhjw7YU2QUeaTJ
# 0uaX4g6B9PFNqAASYLach3CDJiLmYEfus/utPh57mk0q27yL25fXo/PaMDXiDNIi
# 7Wuz7A+sPsbtdiY8zvEIRQ+XJXtKAlD4tqG9YzlTO6ZoQX/rAgMBAAGjggIDMIIB
# /zAfBgNVHSMEGDAWgBRoN+Drtjv4XxGG+/5hewiIZfROQjAdBgNVHQ4EFgQURH4F
# u5yEAuElYWUbyGRYkNLLrA8wPgYDVR0gBDcwNTAzBgZngQwBBAEwKTAnBggrBgEF
# BQcCARYbaHR0cDovL3d3dy5kaWdpY2VydC5jb20vQ1BTMA4GA1UdDwEB/wQEAwIH
# gDATBgNVHSUEDDAKBggrBgEFBQcDAzCBtQYDVR0fBIGtMIGqMFOgUaBPhk1odHRw
# Oi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRDb2RlU2lnbmlu
# Z1JTQTQwOTZTSEEzODQyMDIxQ0ExLmNybDBToFGgT4ZNaHR0cDovL2NybDQuZGln
# aWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZEc0Q29kZVNpZ25pbmdSU0E0MDk2U0hB
# Mzg0MjAyMUNBMS5jcmwwgZQGCCsGAQUFBwEBBIGHMIGEMCQGCCsGAQUFBzABhhho
# dHRwOi8vb2NzcC5kaWdpY2VydC5jb20wXAYIKwYBBQUHMAKGUGh0dHA6Ly9jYWNl
# cnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNENvZGVTaWduaW5nUlNB
# NDA5NlNIQTM4NDIwMjFDQTEuY3J0MAkGA1UdEwQCMAAwDQYJKoZIhvcNAQELBQAD
# ggIBAFiCyuI6qmaQodDyMNpp0l7eIXFgJ4JI59o59PleFj4rcyd/+F4iI7u5if8G
# rV5Kn3s3tK9vfJO8SpqtEh7lL4e69z6v3ohcy4uy2hsjKQ/fFcDo9pQYDGmDVjCa
# D5qSVEIBlJHBe5NKEJAgUE0kaMjLzbi2+8DKJlNtvZ+hatuPl9fMnmU+VbQh7JhZ
# yJdz8Ay0tcQ9lC8HAX5Ah/pU+Vtv+c8gMSxjS1aWXoGCa1869IVi2O6qx7MuX12U
# 1eIpB9XxYr7HSebvg2G7Gz6nCh7u+4k7m3hJu9EStUIN2JII5260+E60uDWoHEhx
# tHbdueFQxJrTKnhplOSaaPFCVBDkWG83ZzN9N3z/45w1pBUNBiPJdRQJ58MhBYQe
# Zl90heMBL8QNQk2i0E5gHNT9pJiCR9+mvJkRxEVgUn+16ZpVnI6kzhThV9qBaWVF
# h83X4UWc/nwHKIuu+4x4fmkYc79A3MrsHflZIO8jOy0GC/xBnZTQ8s5b9Tb2UkHk
# w692Ypl7War3W7M37JCAPC/A7M4CwQYjdjG43zs5m36auYVaTvRLKtZVLzcj8oZX
# 4vqhlZ8+jCPXFiuDfoBXiTckTLpv/eHQ6q7Aoda+qARWPPE1U2v5r/lpKVqIx7B4
# PdFZAUf5MtG/Bj7LVXvXjW8ABIJv7L4cI2akn6Es0dmvd6PsMYIZ6TCCGeUCAQEw
# fTBpMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xQTA/BgNV
# BAMTOERpZ2lDZXJ0IFRydXN0ZWQgRzQgQ29kZSBTaWduaW5nIFJTQTQwOTYgU0hB
# Mzg0IDIwMjEgQ0ExAhAJvPMqSNxAYhV5FFpsbzOhMA0GCWCGSAFlAwQCAQUAoHww
# EAYKKwYBBAGCNwIBDDECMAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYK
# KwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIF380mQn
# 7HmRCEkEMmAPw1rjbMsR++2WZz6rKdN4P8k5MA0GCSqGSIb3DQEBAQUABIIBgG4H
# +3wj9Dgfoxsw741i7bE5Qmoo7ffX/xXHrn1W4AgAAxbXMCneOCqQPZQmwPo1qzsC
# NLtYO6WozK0daUj8ZWrqo7V8ACtMpUpPl2EqZvKTaqipYPTt6nSwrbhEZUkzJ10m
# AQ2TkFFcLq5iUbOCRZQgkSSA8Kkss3eofz+kEmcZIrD3VyNes7qeoX1fwoubLLXD
# ebwR+WZYNKt/4scBE4Doz4cw2k+72eKc5Wyf5UigfEVfNBPWlShikkmz+ksNngtR
# YTW0zYo7LJc8UKT3dP1s1U+I+3r8NBaX5e/Vz+mcH0zXQ7ATvZAw2mQkCDKT0aV6
# fAYwCINslVlo1Hq7uTFBrDDdO+QSSOvigJVjXclX5Gmf+e0GgoTtSiH5WFgiduQy
# 02TN9JzzilyfIqmepJ+nrcIeal/cDcp2n2pcqqiF45xy5Uk9GQgLG20bPvb0wJCW
# tLPZSE5hDf7OMv2ImzsLH4asebTYixN/OcVlKtYgj/zxl3SQCFF3VO9Rg588BqGC
# Fz8wghc7BgorBgEEAYI3AwMBMYIXKzCCFycGCSqGSIb3DQEHAqCCFxgwghcUAgED
# MQ8wDQYJYIZIAWUDBAIBBQAwdwYLKoZIhvcNAQkQAQSgaARmMGQCAQEGCWCGSAGG
# /WwHATAxMA0GCWCGSAFlAwQCAQUABCDDVv/b4/DlXHBdi8HDz9vRSpBYkDIW/8zA
# XzjZDH/HHgIQHi6DJZenqUxaQEksNvnfLxgPMjAyNDA4MjcxNjU1NTBaoIITCTCC
# BsIwggSqoAMCAQICEAVEr/OUnQg5pr/bP1/lYRYwDQYJKoZIhvcNAQELBQAwYzEL
# MAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYDVQQDEzJE
# aWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2IFRpbWVTdGFtcGluZyBD
# QTAeFw0yMzA3MTQwMDAwMDBaFw0zNDEwMTMyMzU5NTlaMEgxCzAJBgNVBAYTAlVT
# MRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjEgMB4GA1UEAxMXRGlnaUNlcnQgVGlt
# ZXN0YW1wIDIwMjMwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQCjU0WH
# HYOOW6w+VLMj4M+f1+XS512hDgncL0ijl3o7Kpxn3GIVWMGpkxGnzaqyat0QKYoe
# YmNp01icNXG/OpfrlFCPHCDqx5o7L5Zm42nnaf5bw9YrIBzBl5S0pVCB8s/LB6Yw
# aMqDQtr8fwkklKSCGtpqutg7yl3eGRiF+0XqDWFsnf5xXsQGmjzwxS55DxtmUuPI
# 1j5f2kPThPXQx/ZILV5FdZZ1/t0QoRuDwbjmUpW1R9d4KTlr4HhZl+NEK0rVlc7v
# CBfqgmRN/yPjyobutKQhZHDr1eWg2mOzLukF7qr2JPUdvJscsrdf3/Dudn0xmWVH
# VZ1KJC+sK5e+n+T9e3M+Mu5SNPvUu+vUoCw0m+PebmQZBzcBkQ8ctVHNqkxmg4ho
# Yru8QRt4GW3k2Q/gWEH72LEs4VGvtK0VBhTqYggT02kefGRNnQ/fztFejKqrUBXJ
# s8q818Q7aESjpTtC/XN97t0K/3k0EH6mXApYTAA+hWl1x4Nk1nXNjxJ2VqUk+tfE
# ayG66B80mC866msBsPf7Kobse1I4qZgJoXGybHGvPrhvltXhEBP+YUcKjP7wtsfV
# x95sJPC/QoLKoHE9nJKTBLRpcCcNT7e1NtHJXwikcKPsCvERLmTgyyIryvEoEyFJ
# UX4GZtM7vvrrkTjYUQfKlLfiUKHzOtOKg8tAewIDAQABo4IBizCCAYcwDgYDVR0P
# AQH/BAQDAgeAMAwGA1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgw
# IAYDVR0gBBkwFzAIBgZngQwBBAIwCwYJYIZIAYb9bAcBMB8GA1UdIwQYMBaAFLoW
# 2W1NhS9zKXaaL3WMaiCPnshvMB0GA1UdDgQWBBSltu8T5+/N0GSh1VapZTGj3tXj
# STBaBgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGln
# aUNlcnRUcnVzdGVkRzRSU0E0MDk2U0hBMjU2VGltZVN0YW1waW5nQ0EuY3JsMIGQ
# BggrBgEFBQcBAQSBgzCBgDAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNl
# cnQuY29tMFgGCCsGAQUFBzAChkxodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20v
# RGlnaUNlcnRUcnVzdGVkRzRSU0E0MDk2U0hBMjU2VGltZVN0YW1waW5nQ0EuY3J0
# MA0GCSqGSIb3DQEBCwUAA4ICAQCBGtbeoKm1mBe8cI1PijxonNgl/8ss5M3qXSKS
# 7IwiAqm4z4Co2efjxe0mgopxLxjdTrbebNfhYJwr7e09SI64a7p8Xb3CYTdoSXej
# 65CqEtcnhfOOHpLawkA4n13IoC4leCWdKgV6hCmYtld5j9smViuw86e9NwzYmHZP
# VrlSwradOKmB521BXIxp0bkrxMZ7z5z6eOKTGnaiaXXTUOREEr4gDZ6pRND45Ul3
# CFohxbTPmJUaVLq5vMFpGbrPFvKDNzRusEEm3d5al08zjdSNd311RaGlWCZqA0Xe
# 2VC1UIyvVr1MxeFGxSjTredDAHDezJieGYkD6tSRN+9NUvPJYCHEVkft2hFLjDLD
# iOZY4rbbPvlfsELWj+MXkdGqwFXjhr+sJyxB0JozSqg21Llyln6XeThIX8rC3D0y
# 33XWNmdaifj2p8flTzU8AL2+nCpseQHc2kTmOt44OwdeOVj0fHMxVaCAEcsUDH6u
# vP6k63llqmjWIso765qCNVcoFstp8jKastLYOrixRoZruhf9xHdsFWyuq69zOuhJ
# RrfVf8y2OMDY7Bz1tqG4QyzfTkx9HmhwwHcK1ALgXGC7KP845VJa1qwXIiNO9OzT
# F/tQa/8Hdx9xl0RBybhG02wyfFgvZ0dl5Rtztpn5aywGRu9BHvDwX+Db2a2QgESv
# gBBBijCCBq4wggSWoAMCAQICEAc2N7ckVHzYR6z9KGYqXlswDQYJKoZIhvcNAQEL
# BQAwYjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UE
# CxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQgVHJ1c3RlZCBS
# b290IEc0MB4XDTIyMDMyMzAwMDAwMFoXDTM3MDMyMjIzNTk1OVowYzELMAkGA1UE
# BhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYDVQQDEzJEaWdpQ2Vy
# dCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2IFRpbWVTdGFtcGluZyBDQTCCAiIw
# DQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAMaGNQZJs8E9cklRVcclA8TykTep
# l1Gh1tKD0Z5Mom2gsMyD+Vr2EaFEFUJfpIjzaPp985yJC3+dH54PMx9QEwsmc5Zt
# +FeoAn39Q7SE2hHxc7Gz7iuAhIoiGN/r2j3EF3+rGSs+QtxnjupRPfDWVtTnKC3r
# 07G1decfBmWNlCnT2exp39mQh0YAe9tEQYncfGpXevA3eZ9drMvohGS0UvJ2R/dh
# gxndX7RUCyFobjchu0CsX7LeSn3O9TkSZ+8OpWNs5KbFHc02DVzV5huowWR0QKfA
# csW6Th+xtVhNef7Xj3OTrCw54qVI1vCwMROpVymWJy71h6aPTnYVVSZwmCZ/oBpH
# IEPjQ2OAe3VuJyWQmDo4EbP29p7mO1vsgd4iFNmCKseSv6De4z6ic/rnH1pslPJS
# lRErWHRAKKtzQ87fSqEcazjFKfPKqpZzQmiftkaznTqj1QPgv/CiPMpC3BhIfxQ0
# z9JMq++bPf4OuGQq+nUoJEHtQr8FnGZJUlD0UfM2SU2LINIsVzV5K6jzRWC8I41Y
# 99xh3pP+OcD5sjClTNfpmEpYPtMDiP6zj9NeS3YSUZPJjAw7W4oiqMEmCPkUEBID
# fV8ju2TjY+Cm4T72wnSyPx4JduyrXUZ14mCjWAkBKAAOhFTuzuldyF4wEr1GnrXT
# drnSDmuZDNIztM2xAgMBAAGjggFdMIIBWTASBgNVHRMBAf8ECDAGAQH/AgEAMB0G
# A1UdDgQWBBS6FtltTYUvcyl2mi91jGogj57IbzAfBgNVHSMEGDAWgBTs1+OC0nFd
# ZEzfLmc/57qYrhwPTzAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0lBAwwCgYIKwYBBQUH
# AwgwdwYIKwYBBQUHAQEEazBpMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdp
# Y2VydC5jb20wQQYIKwYBBQUHMAKGNWh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNv
# bS9EaWdpQ2VydFRydXN0ZWRSb290RzQuY3J0MEMGA1UdHwQ8MDowOKA2oDSGMmh0
# dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRSb290RzQuY3Js
# MCAGA1UdIAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG/WwHATANBgkqhkiG9w0BAQsF
# AAOCAgEAfVmOwJO2b5ipRCIBfmbW2CFC4bAYLhBNE88wU86/GPvHUF3iSyn7cIoN
# qilp/GnBzx0H6T5gyNgL5Vxb122H+oQgJTQxZ822EpZvxFBMYh0MCIKoFr2pVs8V
# c40BIiXOlWk/R3f7cnQU1/+rT4osequFzUNf7WC2qk+RZp4snuCKrOX9jLxkJods
# kr2dfNBwCnzvqLx1T7pa96kQsl3p/yhUifDVinF2ZdrM8HKjI/rAJ4JErpknG6sk
# HibBt94q6/aesXmZgaNWhqsKRcnfxI2g55j7+6adcq/Ex8HBanHZxhOACcS2n82H
# hyS7T6NJuXdmkfFynOlLAlKnN36TU6w7HQhJD5TNOXrd/yVjmScsPT9rp/Fmw0HN
# T7ZAmyEhQNC3EyTN3B14OuSereU0cZLXJmvkOHOrpgFPvT87eK1MrfvElXvtCl8z
# OYdBeHo46Zzh3SP9HSjTx/no8Zhf+yvYfvJGnXUsHicsJttvFXseGYs2uJPU5vIX
# mVnKcPA3v5gA3yAWTyf7YGcWoWa63VXAOimGsJigK+2VQbc61RWYMbRiCQ8KvYHZ
# E/6/pNHzV9m8BPqC3jLfBInwAM1dwvnQI38AC+R2AibZ8GV2QqYphwlHK+Z/GqSF
# D/yYlvZVVCsfgPrA8g4r5db7qS9EFUrnEw4d2zc4GqEr9u3WfPwwggWNMIIEdaAD
# AgECAhAOmxiO+dAt5+/bUOIIQBhaMA0GCSqGSIb3DQEBDAUAMGUxCzAJBgNVBAYT
# AlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2Vy
# dC5jb20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0y
# MjA4MDEwMDAwMDBaFw0zMTExMDkyMzU5NTlaMGIxCzAJBgNVBAYTAlVTMRUwEwYD
# VQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAf
# BgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDCCAiIwDQYJKoZIhvcNAQEB
# BQADggIPADCCAgoCggIBAL/mkHNo3rvkXUo8MCIwaTPswqclLskhPfKK2FnC4Smn
# PVirdprNrnsbhA3EMB/zG6Q4FutWxpdtHauyefLKEdLkX9YFPFIPUh/GnhWlfr6f
# qVcWWVVyr2iTcMKyunWZanMylNEQRBAu34LzB4TmdDttceItDBvuINXJIB1jKS3O
# 7F5OyJP4IWGbNOsFxl7sWxq868nPzaw0QF+xembud8hIqGZXV59UWI4MK7dPpzDZ
# Vu7Ke13jrclPXuU15zHL2pNe3I6PgNq2kZhAkHnDeMe2scS1ahg4AxCN2NQ3pC4F
# fYj1gj4QkXCrVYJBMtfbBHMqbpEBfCFM1LyuGwN1XXhm2ToxRJozQL8I11pJpMLm
# qaBn3aQnvKFPObURWBf3JFxGj2T3wWmIdph2PVldQnaHiZdpekjw4KISG2aadMre
# Sx7nDmOu5tTvkpI6nj3cAORFJYm2mkQZK37AlLTSYW3rM9nF30sEAMx9HJXDj/ch
# srIRt7t/8tWMcCxBYKqxYxhElRp2Yn72gLD76GSmM9GJB+G9t+ZDpBi4pncB4Q+U
# DCEdslQpJYls5Q5SUUd0viastkF13nqsX40/ybzTQRESW+UQUOsxxcpyFiIJ33xM
# dT9j7CFfxCBRa2+xq4aLT8LWRV+dIPyhHsXAj6KxfgommfXkaS+YHS312amyHeUb
# AgMBAAGjggE6MIIBNjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTs1+OC0nFd
# ZEzfLmc/57qYrhwPTzAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzAO
# BgNVHQ8BAf8EBAMCAYYweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRw
# Oi8vb2NzcC5kaWdpY2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRz
# LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwRQYDVR0f
# BD4wPDA6oDigNoY0aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNz
# dXJlZElEUm9vdENBLmNybDARBgNVHSAECjAIMAYGBFUdIAAwDQYJKoZIhvcNAQEM
# BQADggEBAHCgv0NcVec4X6CjdBs9thbX979XB72arKGHLOyFXqkauyL4hxppVCLt
# pIh3bb0aFPQTSnovLbc47/T/gLn4offyct4kvFIDyE7QKt76LVbP+fT3rDB6mouy
# XtTP0UNEm0Mh65ZyoUi0mcudT6cGAxN3J0TU53/oWajwvy8LpunyNDzs9wPHh6jS
# TEAZNUZqaVSwuKFWjuyk1T3osdz9HNj0d1pcVIxv76FQPfx2CWiEn2/K2yCNNWAc
# AgPLILCsWKAOQGPFmCLBsln1VWvPJ6tsds5vIy30fnFqI2si/xK4VC0nftg62fC2
# h5b9W9FcrBjDTZ9ztwGpn1eqXijiuZQxggN2MIIDcgIBATB3MGMxCzAJBgNVBAYT
# AlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQg
# VHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0ECEAVEr/OU
# nQg5pr/bP1/lYRYwDQYJYIZIAWUDBAIBBQCggdEwGgYJKoZIhvcNAQkDMQ0GCyqG
# SIb3DQEJEAEEMBwGCSqGSIb3DQEJBTEPFw0yNDA4MjcxNjU1NTBaMCsGCyqGSIb3
# DQEJEAIMMRwwGjAYMBYEFGbwKzLCwskPgl3OqorJxk8ZnM9AMC8GCSqGSIb3DQEJ
# BDEiBCBX+6gNSGt3oKmrcz3KfhudFp27D0PZoI9G+4muN5uKvjA3BgsqhkiG9w0B
# CRACLzEoMCYwJDAiBCDS9uRt7XQizNHUQFdoQTZvgoraVZquMxavTRqa1Ax4KDAN
# BgkqhkiG9w0BAQEFAASCAgBMnWjwOIYgaWjnBy/p1npT+cBEHIeudxoVZSPblFGM
# o5lxa790X5udndZBhhjbGXX19mPC/NT3kFgVeJloKqy5j9HB/p9ewlRsx0i+bAA3
# ABTpOMYm42+qLUTvaDdm4rveqGhkFtiLaAfjxJ3mAaYkYNfRbB6nmVsMICTO1OAB
# VtZus4depzu57GCqpYZ9RdBrj86ucVuvt2oWPI/TH5Hc2CExQtolgoyF+ySN+VAB
# uw3LmVoj3RJj/wYND9gc77EbC1qndNdR1+1KYRa/+wT3B14WVnO8QplaY0V75W/e
# 5IglE4A8pydQaUYYzF3iQU/cIk1qVSxkhklcXyDOAg49gG4d9+YN0AdMacOnyrcl
# EgSDtO/Tny5SIarwF9A28Fuq8zK1C3yJFjPrEpi2p/IBQ8BpGlFH4Xx5wC0/S8tF
# Og2LUsEwOYrhWQBjVQ17mAWTqJdRrJvCr1x6cJ+295thhn8vc3MVt6uXyNuY44Fl
# 8n8yxfx8eeAWMH/3eSUpb8BLHjfh0VP5fab3pqU0dioQiEueNJDz5iYHOk8sHfPy
# WYC5IYbkchErQhcRNRrbfdi9VzbzjDaxAvh24XBRQn4fDmUviNvbU8fs93VC3XUf
# y9yD4jdYQW/MH8xxgDq2mgOaGXwI7I5RJimukwHfoFOoaG1L4RZy4wQsRgW/E29u
# Kg==
# SIG # End signature block
