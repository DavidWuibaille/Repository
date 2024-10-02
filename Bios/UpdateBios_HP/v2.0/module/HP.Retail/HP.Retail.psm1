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

using namespace HP.CMSLHelper

Set-StrictMode -Version 3.0
#requires -Modules "HP.Private", "HP.Firmware"

# CMSL is normally installed in C:\Program Files\WindowsPowerShell\Modules
# but if installed via PSGallery and via PS7, it is installed in a different location
if (Test-Path "$PSScriptRoot\..\HP.Private\HP.CMSLHelper.dll") {
  Add-Type -Path "$PSScriptRoot\..\HP.Private\HP.CMSLHelper.dll"
}
else{
  Add-Type -Path "$PSScriptRoot\..\..\HP.Private\1.7.2\HP.CMSLHelper.dll"
}

enum RetailDockStatus{
  NotDocked = 0
  Docked = 1
  Jammed = 2
  Unknown = 0xff
}


enum RetailHubType{
  NotPresent = 0
  AdvancedConnectivityBase = 1
  BasicConnectivityBase = 2
  Unknown = 0xff
}


enum RetailDockMode{
  FastRelease = 0
  FastReleaseAndPIN = 1
  Privileged = 2
  PrivilegedAndPIN = 3
  Application = 4
  Unknown = 0xff
}


<#
.SYNOPSIS
  Retrieves information about an HP Retail system

.DESCRIPTION
  This command retrieves information about an HP Retail system such as the HP Engage system.


.PARAMETER ShowPin
  If specified, this command will show the PIN in the output. 


.EXAMPLE
  Get-HPRetailSmartDockConfiguration -ShowPin


.NOTES
  - This command requires elevated privileges.
  - This is a special purpose command that will only execute successfully in the presence of supported hardware.

#>
function Get-HPRetailSmartDockConfiguration {
  [CmdletBinding(HelpUri = "https://developers.hp.com/hp-client-management/doc/Get-HPRetailSmartDockConfiguration")]
  param(
    [switch]$ShowPin
  )

  [RetailInformation]$c = Get-HPPrivateRetailConfiguration
  $configuration = [ordered]@{
    RetailSmartDockSupported = $false
  }
  if ($c.IsSupported) {

    Write-Verbose 'Firmware supports retail smart dock'
    $configuration.RetailSmartDockSupported = $true
    $configuration.Add("RetailSmartDockMode",[RetailDockMode]$c.Mode)
    $configuration.Add("RetailSmartDockTimeoutSeconds",$c.Timeout) # what is 'timeout' ?
    $configuration.Add("RetailSmartDockState",[RetailDockStatus]$c.DockState)
    $configuration.Add("RetailSmartDockHub",[RetailHubType]$c.HubState)
    $configuration.Add("RetailSmartDockDockCounter",$c.DockCounter)
    #$configuration.Add("RetailSmartDockUndockCounter",$c.UndockCounter)
    $configuration.Add("RetailSmartDockBaseLockoutSeconds",$c.BaseLockoutTimer)
    $configuration.Add("RetailSmartDockRelockSeconds",$c.RelockTimer)


    if ($c.PinSize) {
      $configuration.PinIsSet = $true

      if ($ShowPin.IsPresent) {
        $configuration.Add("ActivePIN",[System.Text.Encoding]::UTF8.GetString($c.Pin).trim())

      }
    }
    else {
      $configuration.PinIsSet = $false
    }

  }
  else {
    Write-Verbose 'Firmware does not support retail smart dock'
  }
  $configuration
}


<#
.SYNOPSIS
  Configures an HP Retail System

.DESCRIPTION
  This command configures the settings of an HP Retail system such as the HP Engage Go system. 

.PARAMETER Mode
  Specifies the mode to activate. The value must be one of the following values: 

    - FastRelease: Default mode where no authentication is required. Simply unlock the tablet with the touch of a button. Do not use the -PIN parameter. 
    - FastReleaseAndPIN: A PIN is required to unlock the tablet.
    - Privileged: Only privileged users (users with admin login) can unlock the tablet. Do not use PIN parameter. 
    - PrivilegedAndPIN: Only privileged users (users with admin login) with a PIN can unlock the tablet.
    - Application: Mode for applications. A PIN is required. 

.PARAMETER PIN
  Specifies the PIN to set. The PIN must be a numeric string between 4 and 10 characters. This parameter is mandatory for 'FastReleaseAndPIN', 'PrivilegedAndPIN', and 'Application'. This parameter must not be supplied for the other modes.

.PARAMETER PINData
  Specifies the SecureString PINData to use

.PARAMETER BaseLockoutTime
  Sets the base lockout time in seconds. This must be a value between 30 and 1800 seconds.

.PARAMETER RelockTime
  Sets the relock time in seconds. This must be a value between 10 and 300 seconds.


.EXAMPLE
  Set-HPRetailSmartDockConfiguration -Mode PrivilegedAndPIN -PIN 123456

.NOTES
 - This command requires elevated privileges.
 - This is a special purpose command that will only execute successfully in the presence of supported hardware.

#>

function Set-HPRetailSmartDockConfiguration {
  [CmdletBinding(HelpUri = "https://developers.hp.com/hp-client-management/doc/Set-HPRetailSmartDockConfiguration")]
  param(
    [Parameter(ParameterSetName = 'Mode',Position = 0,Mandatory = $true)]
    [Parameter(ParameterSetName = 'ModePin',Position = 0,Mandatory = $true)]
    [Parameter(ParameterSetName = 'ModeSPin',Position = 0,Mandatory = $true)]
    [ValidateSet('FastRelease','FastReleaseAndPIN','Privileged','PrivilegedAndPIN','Application')]
    [RetailDockMode]$Mode = 'Unknown',


    [Parameter(ParameterSetName = 'ModePin',Position = 1,Mandatory = $true)]
    [ValidatePattern("^\d*$")]
    [ValidateLength(4,10)]
    [string]$PIN,

    [Parameter(ParameterSetName = 'ModeSPin',Position = 1,Mandatory = $true)]
    [securestring]$PINData,


    [Parameter(ParameterSetName = 'All',Position = 2,Mandatory = $false)]
    [Parameter(ParameterSetName = 'Mode',Position = 2,Mandatory = $false)]
    [Parameter(ParameterSetName = 'ModePin',Position = 2,Mandatory = $false)]
    [Parameter(ParameterSetName = 'ModeSPin',Position = 2,Mandatory = $false)]
    [ValidatePattern("^\d*$")]
    [ValidateRange(30,1800)]
    [int]$BaseLockoutTime = 0,

    [Parameter(ParameterSetName = 'All',Position = 3,Mandatory = $false)]
    [Parameter(ParameterSetName = 'Mode',Position = 3,Mandatory = $false)]
    [Parameter(ParameterSetName = 'ModePin',Position = 3,Mandatory = $false)]
    [Parameter(ParameterSetName = 'ModeSPin',Position = 3,Mandatory = $false)]
    [ValidatePattern("^\d*$")]
    [ValidateRange(10,300)]
    [int]$RelockTime = 0

  )
  if (($Mode -eq "Unknown") -and (-not $BaseLockoutTime) -and (-not $RelockTime)) {

    Write-Verbose "Nothing to do."
    return
  }
  [RetailInformation]$r = Get-HPPrivateRetailConfiguration -Verbose:$VerbosePreference

  if ($r -and $r.IsSupported) {
    if ($Mode -eq "FastRelease" -or $Mode -eq "Privileged") {
      Write-Verbose "Handling docking mode $Mode (this mode doesn't require a PIN)"
      if ($Pin -or $PINData) {
        Write-Verbose "PIN Specified for mode '$Mode' which does not accept a PIN"
        throw [ArgumentException]"PIN or PINData is not valid for this mode."
      }
      $r.PinSize = 0
      $r.Pin = @(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
    }


    if ($mode -eq "FastReleaseAndPIN" -or $mode -eq "PrivilegedAndPIN" -or $mode -eq "Application") {
      Write-Verbose "Handling docking mode $Mode (this mode requires a PIN)"
      if (-not $Pin -and -not $PinData) {
        Write-Verbose "PIN not specified for mode '$Mode' which requires a PIN"
        throw [ArgumentException]"PIN or PINData may not be null for this mode."
      }
      if ($PinData) {
        Write-Verbose 'Using SecureString PIN'
        $pin = (New-Object System.Net.NetworkCredential -ArgumentList "",$PinData).Password
        if (($pin.Length -lt 4) -or ($pin.Length -gt 10)) {
          throw [ArgumentException]("PIN must be between 4 and 10 characters in length.")

        }
        if (-not $pin -match "^\d*$") {
          throw [ArgumentException]("PIN can only contain characters 0 through 9")
        }
      }
      else {
        Write-Verbose 'Using plain test PIN'
      }

      if ($Pin -or $PinData) {
        $pinbytes = ([System.Text.Encoding]::UTF8.GetBytes($Pin) | ForEach-Object { $_ - 0x30 })
        $padding = New-Object byte[] (16 - $pinbytes.Length)
        $r.Pin = $pinbytes + $padding
        $r.PinSize = $Pin.Length
      }
    }

    $r.Mode = $Mode
    if (-not $pin -and -not $pindata) {
      $r.Pin = $r.Pin | ForEach-Object { if ($_ -ge 0x30) { $_ - 0x30 } else { $_ } }
    }
    if ($BaseLockoutTime) {
      Write-Verbose "Setting BaseLockoutTimer to $BaseLockoutTime seconds"
      $r.BaseLockoutTimer = $BaseLockoutTime
    }

    if ($RelockTime) {
      Write-Verbose "Setting RelockTimer to $RelockTime seconds"
      $r.RelockTimer = $RelockTime
    }

    Set-HPPrivateRetailConfiguration -configuration $r
  }
  else {
    throw [NotSupportedException]"This platform does not support HP Retail Smart Dock"
  }
}



# SIG # Begin signature block
# MIIoHQYJKoZIhvcNAQcCoIIoDjCCKAoCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB2oKP0pK/cNH1M
# geLCFgvkN/KwLafQDvwSQeJhXi8UBqCCDYowggawMIIEmKADAgECAhAIrUCyYNKc
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
# KwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKXrGlVZ
# OiiJH6oZTXqI+gCHu6fJq5ewnKzqJ0V74RoiMA0GCSqGSIb3DQEBAQUABIIBgBsL
# YrDPsxMEX/SXZKGijtFiiDi/jwkSKnmlwaAWMNc/b7jIzav2vjAMNP/yRhTle+sQ
# jgXCOHHqlC6MNcUE0kP+Y8dtBLr386KEnwIjroCMsdaXbvbD8ap/MSYW8WtcmTJ2
# q54FPlGY5Xv/3n55je1do1NolbqwHgvwndV2d2Vu8DsIgx6CmBxds+FxSzMDfWpW
# Hgdia8n15JB7WE5d58Z5IjcSXNV2bUypw42H+ZsHA6bJL29E74RMUKUyVyoa7nSz
# 5HMEGkK3IX6hO8rcfyz3Lpw7mtF8d8H5Z+GElUP2FUkg/Tu81my+ymOE/E0+2uw2
# lfGd8eYUGQpKuIW8dXYAxZuHxRQ54zEl5BiUoRmGYogKCiaPQrq3Dt5A68HfLpcX
# /c2wYELj9YNzEsECld0sxbhiA+/KbB+m3hST/JF4Xx5DBXXWSEhij8fZkUpcuaA+
# 8wYaUvcE/L17Yx9WmrjQim5UrPFUaBPoWbcb+91gZL0A6dn6WzYdYFIkGOHJvaGC
# Fz8wghc7BgorBgEEAYI3AwMBMYIXKzCCFycGCSqGSIb3DQEHAqCCFxgwghcUAgED
# MQ8wDQYJYIZIAWUDBAIBBQAwdwYLKoZIhvcNAQkQAQSgaARmMGQCAQEGCWCGSAGG
# /WwHATAxMA0GCWCGSAFlAwQCAQUABCBDqX/zisAFtIHbDZDtfIGV/E00HpyNiEkJ
# CrkCEfM70AIQJxS53Do1xBQz26aiz/JaNxgPMjAyNDA4MjcxNjU1NTBaoIITCTCC
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
# BDEiBCCzaRaq/zishAnYC9ivj5ucEFINEYBea0HcTW01RQN10jA3BgsqhkiG9w0B
# CRACLzEoMCYwJDAiBCDS9uRt7XQizNHUQFdoQTZvgoraVZquMxavTRqa1Ax4KDAN
# BgkqhkiG9w0BAQEFAASCAgBCK9defdw4A0OE6OE/NTHms6PKaXEvlQiBq3PJCln0
# WpyYR9RwExCfFb32jvVFMgQlcWEgImXO+AsKRKemNBTMQs2U3YSvEpwngFBuvfKO
# pOM6fH6xxkWmKkb29Zn02vlcHfqZkKX7jmogYlP9TngZz/3BpqWVCULeETeT2Ztk
# EEBP0oWi1BIyk/wxp1to9A4uAFydehMVTSweelKSVT7UMtLhcduaM+hiJkEGCuDi
# dRpYaBUykoVMC29ubs3j8jSjEv1k+KjV2qBolNpcaCUlArjwjTbJrReWteYbu9lD
# di6ng8JKD0p7rvxJzZH9HyP5M9dx6Cq8IeAMTAzgtraVbzpy5rdcxGFeDfh3x9LW
# IvIIWOdv+Lq7bTa04eDVkZ1AIi67rSMZS2OrnyWwQ2Imo6IPnRTJXsKKezoigX0E
# ZpfGlhMSuv9XcF0gGGF/ii3TlP/0dJ4BiW2Q+UB5JK3L4bBbFPFnfDFrV40QrP35
# 85/wOXkj50ItZ5tl/OUAfv2Y+LIUJlqJvfZ/hqRTF6R6hvwnvPzDpS9OVtUq1cda
# pQYsUizvGYBSYi4qS4ifCz1c3FiBnUJLKfOq6p6Qk+UQBT42ya1Nzm531T57DcBz
# AW5gjNyOzM3yIkJ664KSe3+tGkaOp+DVTcZfQlPZqHIUW0SYll0S3BXSd/IaaDg2
# qA==
# SIG # End signature block
