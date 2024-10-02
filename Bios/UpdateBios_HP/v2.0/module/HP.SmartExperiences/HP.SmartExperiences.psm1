Set-StrictMode -Version 3.0
#requires -Modules "HP.Private","HP.ClientManagement"

<#
.SYNOPSIS
  Sets Smart Experiences as managed or unmanaged 

.DESCRIPTION
  If Smart Experiences\Policy is not found on the registry, this command sets the 'Privacy Alert' and 'Auto Screen Dimming' features to the default values. 

  The default values for both 'Privacy Alert' and 'Auto Screen Dimming' are:
    - AllowEdit: $true
    - Default: Off
    - Enabled: $false
   
  Use the Set-HPeAISettingValue command to configure the values of the eAI features.

.PARAMETER Enabled
  If set to $true, this command will configure eAi as managed. If set to $false, this command will configure eAI as unmanaged. 

.EXAMPLE
  Set-HPeAIManaged -Enabled $true

.NOTES
  Admin privilege is required.

.LINK
  [Get-HPeAISettingValue](https://developers.hp.com/hp-client-management/doc/Get-HPeAISettingValue)

.LINK
  [Set-HPeAISettingValue](https://developers.hp.com/hp-client-management/doc/Set-HPeAISettingValue)
#>
function Set-HPeAIManaged {
  [CmdletBinding(HelpUri = "https://developers.hp.com/hp-client-management/doc/Set-HPeAIManaged")]
  param(
    [Parameter(Mandatory = $true,Position = 0,ValueFromPipeline = $true)]
    [bool]$Enabled
  )
  $eAIRegPath = 'HKLM:\Software\Policies\HP\SmartExperiences'

  if ((Test-HPSmartExperiencesIsSupported) -eq $false) {
    throw [System.NotSupportedException]"HP Smart Experiences is currently not supported on this platform."
  }

  if (-not (Test-IsElevatedAdmin)) {
    throw [System.Security.AccessControl.PrivilegeNotHeldException]"elevated administrator"
  }

  $reg = Get-Item -Path $eAIRegPath -ErrorAction SilentlyContinue
  if ($null -eq $reg) {
    Write-Verbose "Creating registry entry $eAIRegPath"
    New-Item -Path $eAIRegPath -Force | Out-Null
  }

  if ($true -eq $Enabled) {
    $managed = 1

    # Check if eAI attributes exist, if not, set the defaults
    Write-Verbose "Reading registry path $eAIRegPath\Policy"
    $reg = Get-ItemProperty -Path $eAIRegPath -ErrorAction SilentlyContinue -Name Policy
    if ($reg) {
      Write-Verbose "$eAIRegPath\Policy attributes found"
      try {
        Write-Verbose "Data read: $($reg.Policy)"
        $current = $reg.Policy | ConvertFrom-Json
      }
      catch {
        throw [System.FormatException]"$($_.Exception.Message): Please ensure Policy property contains a valid JSON."
      }
    }
    else {
      $current = [ordered]@{
        attentionDim = [ordered]@{
          allowEdit = $true
          default = 0
          isEnabled = $false
        }
        shoulderSurf = [ordered]@{
          allowEdit = $true
          default = 0
          isEnabled = $false
        }
      }

      $value = $current | ConvertTo-Json -Compress
      Write-Verbose "Setting $eAIRegPath\Policy to defaults $value"
    
      if ($reg) {
        Set-ItemProperty -Path $eAIRegPath -Value $value -Name Policy -Force | Out-Null
      }
      else {
        New-ItemProperty -Path $eAIRegPath -Value $value -Name Policy -Force | Out-Null
      }
    }
  }
  else {
    $managed = 0
  }

  Write-Verbose "Setting $eAIRegPath\Managed to $managed"
  $reg = Get-ItemProperty -Path $eAIRegPath -ErrorAction SilentlyContinue -Name Managed
  if ($reg) {
    Set-ItemProperty -Path $eAIRegPath -Value $managed -Name Managed -Force | Out-Null
  }
  else {
    New-ItemProperty -Path $eAIRegPath -Value $managed -Name Managed -Force | Out-Null
  }
}

<#
.SYNOPSIS
  Checks if eAI is managed on the current device
.DESCRIPTION
  If eAI is managed, this command returns true. Otherwise, this command returns false. If 'SmartExperiences' entry is not found in the registry, false is returned by default.

.EXAMPLE
  Get-HPeAIManaged

.NOTES
  Admin privilege is required.

.LINK
  [Set-HPeAIManaged](https://developers.hp.com/hp-client-management/doc/Set-HPeAIManaged)
#>
function Get-HPeAIManaged {
  [CmdletBinding(HelpUri = "https://developers.hp.com/hp-client-management/doc/Get-HPeAIManaged")]
  param()
  $eAIRegPath = 'HKLM:\Software\Policies\HP\SmartExperiences'

  if ((Test-HPSmartExperiencesIsSupported) -eq $false) {
    throw [System.NotSupportedException]"HP Smart Experiences is currently not supported on this platform."
  }

  if (-not (Test-IsElevatedAdmin)) {
    throw [System.Security.AccessControl.PrivilegeNotHeldException]"elevated administrator"
  }

  Write-Verbose "Reading $eAIRegPath\Managed"
  $reg = Get-ItemProperty -Path $eAIRegPath -ErrorAction SilentlyContinue -Name Managed

  if ($reg) {
    return ($reg.Managed -eq 1)
  }

  return $false
}

<#
.SYNOPSIS
  Configures HP eAI features on the current device

.DESCRIPTION
  Configures HP eAI features on the current device. At this time, only the 'Privacy Alert' feature and the 'Auto Screen Dimming' feature are available to be configured. 

.PARAMETER Name
  Specifies the eAI feature name to configure. The value must be one of the following values:
  - Privacy Alert
  - Auto Screen Dimming

.PARAMETER Enabled
  If set to $true, this command will enable the feature specified in the Name parameter. If set to $false, this command will disable the feature specified in the -Name parameter. 

.PARAMETER AllowEdit
  If set to $true, editing is allowed for the feature specified in the Name parameter. If set to $false, editing is not allowed for the feature specified in the -Name parameter.

.PARAMETER Default
  Sets default value of the feature specified in the -Name parameter. The value must be one of the following values:
  - On
  - Off

.EXAMPLE
  Set-HPeAISettingValue -Name 'Privacy Alert' -Enabled $true -Default 'On' -AllowEdit $false

.EXAMPLE
  Set-HPeAISettingValue -Name 'Privacy Alert' -Enabled $true

.EXAMPLE
  Set-HPeAISettingValue -Name 'Auto Screen Dimming' -Default 'On'

.EXAMPLE
  Set-HPeAISettingValue -Name 'Auto Screen Dimming' -AllowEdit $false

.NOTES
  Admin privilege is required.

.LINK
  [Set-HPeAIManaged](https://developers.hp.com/hp-client-management/doc/Set-HPeAIManaged)

.LINK
  [Get-HPeAISettingValue](https://developers.hp.com/hp-client-management/doc/Get-HPeAISettingValue)
#>
function Set-HPeAISettingValue {
  [CmdletBinding(HelpUri = "https://developers.hp.com/hp-client-management/doc/Set-HPeAISettingValue")]
  param(
    [Parameter(Mandatory = $true,Position = 0,ParameterSetName = 'Enabled')]
    [Parameter(Mandatory = $true,Position = 0,ParameterSetName = 'AllowEdit')]
    [Parameter(Mandatory = $true,Position = 0,ParameterSetName = 'Default')]
    [ValidateSet('Privacy Alert','Auto Screen Dimming')]
    [string]$Name,

    [Parameter(Mandatory = $true,Position = 1,ParameterSetName = 'Enabled')]
    [bool]$Enabled,

    [Parameter(Mandatory = $false,Position = 2,ParameterSetName = 'Enabled')]
    [Parameter(Mandatory = $true,Position = 1,ParameterSetName = 'AllowEdit')]
    [bool]$AllowEdit,

    [Parameter(Mandatory = $false,Position = 3,ParameterSetName = 'Enabled')]
    [Parameter(Mandatory = $false,Position = 2,ParameterSetName = 'AllowEdit')]
    [Parameter(Mandatory = $true,Position = 1,ParameterSetName = 'Default')]
    [ValidateSet('On','Off')]
    [string]$Default
  )
  $eAIFeatures = @{
    'Privacy Alert' = 'shoulderSurf'
    'Auto Screen Dimming' = 'attentionDim'
  }
  $eAIRegPath = 'HKLM:\Software\Policies\HP\SmartExperiences'

  if ((Test-HPSmartExperiencesIsSupported) -eq $false) {
    throw [System.NotSupportedException]"HP Smart Experiences is currently not supported on this platform."
  }

  if (-not (Test-IsElevatedAdmin)) {
    throw [System.Security.AccessControl.PrivilegeNotHeldException]"elevated administrator"
  }

  Write-Verbose "Reading registry path $eAIRegPath\Policy"
  $reg = Get-ItemProperty -Path $eAIRegPath -ErrorAction SilentlyContinue -Name Policy
  if ($reg) {
    try {
      Write-Verbose "Data read: $($reg.Policy)"
      $current = $reg.Policy | ConvertFrom-Json
    }
    catch {
      throw [System.FormatException]"$($_.Exception.Message): Please ensure Policy property contains a valid JSON."
    }
  }
  else {
    $current = [ordered]@{
      attentionDim = [ordered]@{
        allowEdit = $true
        default = 0
        isEnabled = $false
      }
      shoulderSurf = [ordered]@{
        allowEdit = $true
        default = 0
        isEnabled = $false
      }
    }
    Write-Verbose "Creating registry entry with the default values to $eAIRegPath"
    New-Item -Path $eAIRegPath -Force | Out-Null
  }

  Write-Verbose "$($eAIFeatures[$Name]) selected"
  $config = $current.$($eAIFeatures[$Name])
  if ($PSBoundParameters.Keys.Contains('Enabled')) {
    $config.isEnabled = $Enabled
  }
  if ($PSBoundParameters.Keys.Contains('AllowEdit')) {
    $config.allowEdit = $AllowEdit
  }
  if ($PSBoundParameters.Keys.Contains('Default')) {
    $config.default = if ($Default -eq 'On') { 1 } else { 0 }
  }

  $value = $current | ConvertTo-Json -Compress
  Write-Verbose "Setting $eAIRegPath\Policy to $value"

  if ($reg) {
    Set-ItemProperty -Path $eAIRegPath -Value $value -Name Policy -Force | Out-Null
  }
  else {
    New-ItemProperty -Path $eAIRegPath -Value $value -Name Policy -Force | Out-Null
  }

  $reg = Get-ItemProperty -Path $eAIRegPath -ErrorAction SilentlyContinue -Name Managed
  if ($reg) {
    $managed = $reg.Managed
  }
  else {
    $managed = 0
    Write-Verbose "Creating registry entry $eAIRegPath\Managed with default value $managed"
    New-ItemProperty -Path $eAIRegPath -Value $managed -Name Managed -Force | Out-Null
  }
  if ($managed -eq 0) {
    Write-Warning "eAI managed attribute has not been set. Refer to Set-HPeAIManaged function documentation on how to set it."
  }
}

<#
.SYNOPSIS
  Checks if Smart Experiences is supported on the current device

.DESCRIPTION
  This command checks if the BIOS setting "HP Smart Experiences" exists to determine if Smart Experiences is supported on the current device.

.EXAMPLE
  Test-HPSmartExperiencesIsSupported

.LINK
  [Get-HPeAISettingValue](https://developers.hp.com/hp-client-management/doc/Get-HPeAISettingValue)

.LINK
  [Set-HPeAISettingValue](https://developers.hp.com/hp-client-management/doc/Set-HPeAISettingValue)

.LINK
  [Set-HPeAIManaged](https://developers.hp.com/hp-client-management/doc/Set-HPeAIManaged)
#>
function Test-HPSmartExperiencesIsSupported {
  [CmdletBinding(HelpUri = "https://developers.hp.com/hp-client-management/doc/Test-HPSmartExperiencesIsSupported")]
  param()

  [boolean]$status = $false
  try {
    $mode = (Get-HPBIOSSettingValue -Name "HP Smart Experiences")
    $status = $true
  }
  catch {}

  return $status
}

<#
.SYNOPSIS
  Retrieves the values of the specified HP eAI feature from the current device

.DESCRIPTION
  This command retrieves the values of the specified HP eAI feature where the feature must be from the current device. The feature must be either 'Privacy Alert' or 'Auto Screen Dimming'.

.PARAMETER Name
  Specifies the eAI feature to read. The value must be one of the following values:
  - Privacy Alert
  - Auto Screen Dimming

.EXAMPLE
  Get-HPeAISettingValue -Name 'Privacy Alert'

.EXAMPLE
  Get-HPeAISettingValue -Name 'Auto Screen Dimming'

.NOTES
  Admin privilege is required.

.LINK
  [Set-HPeAISettingValue](https://developers.hp.com/hp-client-management/doc/Set-HPeAISettingValue)

.LINK
  [Set-HPeAIManaged](https://developers.hp.com/hp-client-management/doc/Set-HPeAIManaged)
#>
function Get-HPeAISettingValue {
  [CmdletBinding(HelpUri = "https://developers.hp.com/hp-client-management/doc/Get-HPeAISettingValue")]
  param(
    [Parameter(Mandatory = $true,Position = 0)]
    [ValidateSet('Privacy Alert','Auto Screen Dimming')]
    [string]$Name
  )
  $eAIFeatures = @{
    'Privacy Alert' = 'shoulderSurf'
    'Auto Screen Dimming' = 'attentionDim'
  }
  $eAIRegPath = 'HKLM:\Software\Policies\HP\SmartExperiences'

  if ((Test-HPSmartExperiencesIsSupported) -eq $false) {
    throw [System.NotSupportedException]"HP Smart Experiences is currently not supported on this platform."
  }

  Write-Verbose "Reading registry path $eAIRegPath\Policy"
  $reg = Get-ItemProperty -Path $eAIRegPath -ErrorAction SilentlyContinue -Name Policy
  if (-not $reg) {
    throw [System.InvalidOperationException]'HP eAI is not currently configured on your device.'
  }
  else {
    try {
      Write-Verbose "Data read: $($reg.Policy)"
      $current = $reg.Policy | ConvertFrom-Json
    }
    catch {
      throw [System.FormatException]"$($_.Exception.Message): Please ensure Policy property contains a valid JSON."
    }
    Write-Verbose "$($eAIFeatures[$Name]) selected"
    $config = $current.$($eAIFeatures[$Name])

    $reg = Get-ItemProperty -Path $eAIRegPath -ErrorAction SilentlyContinue -Name Managed
    if ($reg) {
      $managed = $reg.Managed
    }
    else {
      $managed = $false
    }
    Write-Verbose "Managed: $managed"

    return [ordered]@{
      Enabled = [bool]$config.isEnabled
      Default = if ($config.default -eq 1) { 'On' } else { 'Off' }
      AllowEdit = [bool]$config.allowEdit
    }
  }
}
# SIG # Begin signature block
# MIIoHgYJKoZIhvcNAQcCoIIoDzCCKAsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD+zdIXquO7YMDR
# GFZo5716vczwSbHf5W7BzvHLkEW9k6CCDYowggawMIIEmKADAgECAhAIrUCyYNKc
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
# PdFZAUf5MtG/Bj7LVXvXjW8ABIJv7L4cI2akn6Es0dmvd6PsMYIZ6jCCGeYCAQEw
# fTBpMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xQTA/BgNV
# BAMTOERpZ2lDZXJ0IFRydXN0ZWQgRzQgQ29kZSBTaWduaW5nIFJTQTQwOTYgU0hB
# Mzg0IDIwMjEgQ0ExAhAJvPMqSNxAYhV5FFpsbzOhMA0GCWCGSAFlAwQCAQUAoHww
# EAYKKwYBBAGCNwIBDDECMAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYK
# KwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIG3E5D4F
# piA2/YErt8Qydv9icCvR5FyGzPBa13rZG6PoMA0GCSqGSIb3DQEBAQUABIIBgKFg
# 0ODgWLVb8WpmrmT/CsNYq4K2BCdE4NzasY4saU/QuCwf0OgbM1PsVxjscKjy9B2z
# 2epg/Ryt9GEer8buSXBRRPReowX8rPSEud+g9XdBKgdvz8e8HtxrvbE3oH+aogqZ
# YenBk3GDJrNbFE1t/kdrxStUfgzONlOi0xRxL6oHlJCo6EIJ9LyE33LU9qEpNqAY
# KLhTsS4rG+Z5c6CI0dUbsivsChCpfk/rizp+8Ovwh2cW9CjSUVPOEMEJx2QTIFQ4
# AevxiW2mQuF8yG/RP+FZ9NgbZn6I+Y21mNclTk8+W3Kw19YPfA73KvZZLX8K4G69
# T8I8kvEFFBEaZQuRV1G9DBaqV5PnrLwB++oKU/t3WBYv4tPiobDK5cri6PWh0JvE
# 6ZuuZ68MWQjMxT/yX7EpnAZuAenL5I4sKfz1Gz63zs/1rE5+ps3jICs+ADaNlfL1
# s0xNuBLyxELqRgolG8JQwYVQ02/AFsFrUqrV/eKLI4n19FnvcFNDj4YcY5O+MKGC
# F0Awghc8BgorBgEEAYI3AwMBMYIXLDCCFygGCSqGSIb3DQEHAqCCFxkwghcVAgED
# MQ8wDQYJYIZIAWUDBAIBBQAweAYLKoZIhvcNAQkQAQSgaQRnMGUCAQEGCWCGSAGG
# /WwHATAxMA0GCWCGSAFlAwQCAQUABCDk3EcGCRMOfPiOVKXPMogflGFSkK0Pk5RS
# PCr48DdI4QIRAOVXI8u0AujA6WUoA2+Pl4oYDzIwMjQwODI3MTY1NTUwWqCCEwkw
# ggbCMIIEqqADAgECAhAFRK/zlJ0IOaa/2z9f5WEWMA0GCSqGSIb3DQEBCwUAMGMx
# CzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMy
# RGlnaUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcg
# Q0EwHhcNMjMwNzE0MDAwMDAwWhcNMzQxMDEzMjM1OTU5WjBIMQswCQYDVQQGEwJV
# UzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xIDAeBgNVBAMTF0RpZ2lDZXJ0IFRp
# bWVzdGFtcCAyMDIzMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAo1NF
# hx2DjlusPlSzI+DPn9fl0uddoQ4J3C9Io5d6OyqcZ9xiFVjBqZMRp82qsmrdECmK
# HmJjadNYnDVxvzqX65RQjxwg6seaOy+WZuNp52n+W8PWKyAcwZeUtKVQgfLPywem
# MGjKg0La/H8JJJSkghraarrYO8pd3hkYhftF6g1hbJ3+cV7EBpo88MUueQ8bZlLj
# yNY+X9pD04T10Mf2SC1eRXWWdf7dEKEbg8G45lKVtUfXeCk5a+B4WZfjRCtK1ZXO
# 7wgX6oJkTf8j48qG7rSkIWRw69XloNpjsy7pBe6q9iT1HbybHLK3X9/w7nZ9MZll
# R1WdSiQvrCuXvp/k/XtzPjLuUjT71Lvr1KAsNJvj3m5kGQc3AZEPHLVRzapMZoOI
# aGK7vEEbeBlt5NkP4FhB+9ixLOFRr7StFQYU6mIIE9NpHnxkTZ0P387RXoyqq1AV
# ybPKvNfEO2hEo6U7Qv1zfe7dCv95NBB+plwKWEwAPoVpdceDZNZ1zY8SdlalJPrX
# xGshuugfNJgvOuprAbD3+yqG7HtSOKmYCaFxsmxxrz64b5bV4RAT/mFHCoz+8LbH
# 1cfebCTwv0KCyqBxPZySkwS0aXAnDU+3tTbRyV8IpHCj7ArxES5k4MsiK8rxKBMh
# SVF+BmbTO77665E42FEHypS34lCh8zrTioPLQHsCAwEAAaOCAYswggGHMA4GA1Ud
# DwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMI
# MCAGA1UdIAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG/WwHATAfBgNVHSMEGDAWgBS6
# FtltTYUvcyl2mi91jGogj57IbzAdBgNVHQ4EFgQUpbbvE+fvzdBkodVWqWUxo97V
# 40kwWgYDVR0fBFMwUTBPoE2gS4ZJaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0Rp
# Z2lDZXJ0VHJ1c3RlZEc0UlNBNDA5NlNIQTI1NlRpbWVTdGFtcGluZ0NBLmNybDCB
# kAYIKwYBBQUHAQEEgYMwgYAwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2lj
# ZXJ0LmNvbTBYBggrBgEFBQcwAoZMaHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29t
# L0RpZ2lDZXJ0VHJ1c3RlZEc0UlNBNDA5NlNIQTI1NlRpbWVTdGFtcGluZ0NBLmNy
# dDANBgkqhkiG9w0BAQsFAAOCAgEAgRrW3qCptZgXvHCNT4o8aJzYJf/LLOTN6l0i
# kuyMIgKpuM+AqNnn48XtJoKKcS8Y3U623mzX4WCcK+3tPUiOuGu6fF29wmE3aEl3
# o+uQqhLXJ4Xzjh6S2sJAOJ9dyKAuJXglnSoFeoQpmLZXeY/bJlYrsPOnvTcM2Jh2
# T1a5UsK2nTipgedtQVyMadG5K8TGe8+c+njikxp2oml101DkRBK+IA2eqUTQ+OVJ
# dwhaIcW0z5iVGlS6ubzBaRm6zxbygzc0brBBJt3eWpdPM43UjXd9dUWhpVgmagNF
# 3tlQtVCMr1a9TMXhRsUo063nQwBw3syYnhmJA+rUkTfvTVLzyWAhxFZH7doRS4wy
# w4jmWOK22z75X7BC1o/jF5HRqsBV44a/rCcsQdCaM0qoNtS5cpZ+l3k4SF/Kwtw9
# Mt911jZnWon49qfH5U81PAC9vpwqbHkB3NpE5jreODsHXjlY9HxzMVWggBHLFAx+
# rrz+pOt5Zapo1iLKO+uagjVXKBbLafIymrLS2Dq4sUaGa7oX/cR3bBVsrquvczro
# SUa31X/MtjjA2Owc9bahuEMs305MfR5ocMB3CtQC4Fxguyj/OOVSWtasFyIjTvTs
# 0xf7UGv/B3cfcZdEQcm4RtNsMnxYL2dHZeUbc7aZ+WssBkbvQR7w8F/g29mtkIBE
# r4AQQYowggauMIIElqADAgECAhAHNje3JFR82Ees/ShmKl5bMA0GCSqGSIb3DQEB
# CwUAMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNV
# BAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQg
# Um9vdCBHNDAeFw0yMjAzMjMwMDAwMDBaFw0zNzAzMjIyMzU5NTlaMGMxCzAJBgNV
# BAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNl
# cnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0EwggIi
# MA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDGhjUGSbPBPXJJUVXHJQPE8pE3
# qZdRodbSg9GeTKJtoLDMg/la9hGhRBVCX6SI82j6ffOciQt/nR+eDzMfUBMLJnOW
# bfhXqAJ9/UO0hNoR8XOxs+4rgISKIhjf69o9xBd/qxkrPkLcZ47qUT3w1lbU5ygt
# 69OxtXXnHwZljZQp09nsad/ZkIdGAHvbREGJ3HxqV3rwN3mfXazL6IRktFLydkf3
# YYMZ3V+0VAshaG43IbtArF+y3kp9zvU5EmfvDqVjbOSmxR3NNg1c1eYbqMFkdECn
# wHLFuk4fsbVYTXn+149zk6wsOeKlSNbwsDETqVcplicu9Yemj052FVUmcJgmf6Aa
# RyBD40NjgHt1biclkJg6OBGz9vae5jtb7IHeIhTZgirHkr+g3uM+onP65x9abJTy
# UpURK1h0QCirc0PO30qhHGs4xSnzyqqWc0Jon7ZGs506o9UD4L/wojzKQtwYSH8U
# NM/STKvvmz3+DrhkKvp1KCRB7UK/BZxmSVJQ9FHzNklNiyDSLFc1eSuo80VgvCON
# WPfcYd6T/jnA+bIwpUzX6ZhKWD7TA4j+s4/TXkt2ElGTyYwMO1uKIqjBJgj5FBAS
# A31fI7tk42PgpuE+9sJ0sj8eCXbsq11GdeJgo1gJASgADoRU7s7pXcheMBK9Rp61
# 03a50g5rmQzSM7TNsQIDAQABo4IBXTCCAVkwEgYDVR0TAQH/BAgwBgEB/wIBADAd
# BgNVHQ4EFgQUuhbZbU2FL3MpdpovdYxqII+eyG8wHwYDVR0jBBgwFoAU7NfjgtJx
# XWRM3y5nP+e6mK4cD08wDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUF
# BwMIMHcGCCsGAQUFBwEBBGswaTAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGln
# aWNlcnQuY29tMEEGCCsGAQUFBzAChjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5j
# b20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNydDBDBgNVHR8EPDA6MDigNqA0hjJo
# dHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNy
# bDAgBgNVHSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwDQYJKoZIhvcNAQEL
# BQADggIBAH1ZjsCTtm+YqUQiAX5m1tghQuGwGC4QTRPPMFPOvxj7x1Bd4ksp+3CK
# Daopafxpwc8dB+k+YMjYC+VcW9dth/qEICU0MWfNthKWb8RQTGIdDAiCqBa9qVbP
# FXONASIlzpVpP0d3+3J0FNf/q0+KLHqrhc1DX+1gtqpPkWaeLJ7giqzl/Yy8ZCaH
# bJK9nXzQcAp876i8dU+6WvepELJd6f8oVInw1YpxdmXazPByoyP6wCeCRK6ZJxur
# JB4mwbfeKuv2nrF5mYGjVoarCkXJ38SNoOeY+/umnXKvxMfBwWpx2cYTgAnEtp/N
# h4cku0+jSbl3ZpHxcpzpSwJSpzd+k1OsOx0ISQ+UzTl63f8lY5knLD0/a6fxZsNB
# zU+2QJshIUDQtxMkzdwdeDrknq3lNHGS1yZr5Dhzq6YBT70/O3itTK37xJV77Qpf
# MzmHQXh6OOmc4d0j/R0o08f56PGYX/sr2H7yRp11LB4nLCbbbxV7HhmLNriT1Oby
# F5lZynDwN7+YAN8gFk8n+2BnFqFmut1VwDophrCYoCvtlUG3OtUVmDG0YgkPCr2B
# 2RP+v6TR81fZvAT6gt4y3wSJ8ADNXcL50CN/AAvkdgIm2fBldkKmKYcJRyvmfxqk
# hQ/8mJb2VVQrH4D6wPIOK+XW+6kvRBVK5xMOHds3OBqhK/bt1nz8MIIFjTCCBHWg
# AwIBAgIQDpsYjvnQLefv21DiCEAYWjANBgkqhkiG9w0BAQwFADBlMQswCQYDVQQG
# EwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNl
# cnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0EwHhcN
# MjIwODAxMDAwMDAwWhcNMzExMTA5MjM1OTU5WjBiMQswCQYDVQQGEwJVUzEVMBMG
# A1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEw
# HwYDVQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQC/5pBzaN675F1KPDAiMGkz7MKnJS7JIT3yithZwuEp
# pz1Yq3aaza57G4QNxDAf8xukOBbrVsaXbR2rsnnyyhHS5F/WBTxSD1Ifxp4VpX6+
# n6lXFllVcq9ok3DCsrp1mWpzMpTREEQQLt+C8weE5nQ7bXHiLQwb7iDVySAdYykt
# zuxeTsiT+CFhmzTrBcZe7FsavOvJz82sNEBfsXpm7nfISKhmV1efVFiODCu3T6cw
# 2Vbuyntd463JT17lNecxy9qTXtyOj4DatpGYQJB5w3jHtrHEtWoYOAMQjdjUN6Qu
# BX2I9YI+EJFwq1WCQTLX2wRzKm6RAXwhTNS8rhsDdV14Ztk6MUSaM0C/CNdaSaTC
# 5qmgZ92kJ7yhTzm1EVgX9yRcRo9k98FpiHaYdj1ZXUJ2h4mXaXpI8OCiEhtmmnTK
# 3kse5w5jrubU75KSOp493ADkRSWJtppEGSt+wJS00mFt6zPZxd9LBADMfRyVw4/3
# IbKyEbe7f/LVjHAsQWCqsWMYRJUadmJ+9oCw++hkpjPRiQfhvbfmQ6QYuKZ3AeEP
# lAwhHbJUKSWJbOUOUlFHdL4mrLZBdd56rF+NP8m800ERElvlEFDrMcXKchYiCd98
# THU/Y+whX8QgUWtvsauGi0/C1kVfnSD8oR7FwI+isX4KJpn15GkvmB0t9dmpsh3l
# GwIDAQABo4IBOjCCATYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQU7NfjgtJx
# XWRM3y5nP+e6mK4cD08wHwYDVR0jBBgwFoAUReuir/SSy4IxLVGLp6chnfNtyA8w
# DgYDVR0PAQH/BAQDAgGGMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0
# cDovL29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0
# cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MEUGA1Ud
# HwQ+MDwwOqA4oDaGNGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFz
# c3VyZWRJRFJvb3RDQS5jcmwwEQYDVR0gBAowCDAGBgRVHSAAMA0GCSqGSIb3DQEB
# DAUAA4IBAQBwoL9DXFXnOF+go3QbPbYW1/e/Vwe9mqyhhyzshV6pGrsi+IcaaVQi
# 7aSId229GhT0E0p6Ly23OO/0/4C5+KH38nLeJLxSA8hO0Cre+i1Wz/n096wwepqL
# sl7Uz9FDRJtDIeuWcqFItJnLnU+nBgMTdydE1Od/6Fmo8L8vC6bp8jQ87PcDx4eo
# 0kxAGTVGamlUsLihVo7spNU96LHc/RzY9HdaXFSMb++hUD38dglohJ9vytsgjTVg
# HAIDyyCwrFigDkBjxZgiwbJZ9VVrzyerbHbObyMt9H5xaiNrIv8SuFQtJ37YOtnw
# toeW/VvRXKwYw02fc7cBqZ9Xql4o4rmUMYIDdjCCA3ICAQEwdzBjMQswCQYDVQQG
# EwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0
# IFRydXN0ZWQgRzQgUlNBNDA5NiBTSEEyNTYgVGltZVN0YW1waW5nIENBAhAFRK/z
# lJ0IOaa/2z9f5WEWMA0GCWCGSAFlAwQCAQUAoIHRMBoGCSqGSIb3DQEJAzENBgsq
# hkiG9w0BCRABBDAcBgkqhkiG9w0BCQUxDxcNMjQwODI3MTY1NTUwWjArBgsqhkiG
# 9w0BCRACDDEcMBowGDAWBBRm8CsywsLJD4JdzqqKycZPGZzPQDAvBgkqhkiG9w0B
# CQQxIgQgWQRD2ghfeaImF78bXCa5HIAtTqSXvf1gHvUVq3PoWKIwNwYLKoZIhvcN
# AQkQAi8xKDAmMCQwIgQg0vbkbe10IszR1EBXaEE2b4KK2lWarjMWr00amtQMeCgw
# DQYJKoZIhvcNAQEBBQAEggIAUnAxPfemHAq9yvw51ZkYG2sx3tJy0OAapCvFleWN
# KDdFTTEsmw+yc8By67U33msz0ZEAdxuCZ7VNFn1groOvHBQ+Ryte4m72WmwOneyq
# 2ifStMIpO6yO5fExymbq2S83AnzxLbGZf40NKdRkywzZ5gSPYXvnCfb4d4ONzPNl
# G+AjGi8VBg6g9JKPMF7CGyO6FsL2H4Ab1YoSHbhOCZNF7zFgnSImC81vYggqPhQ3
# kPJF7oOMRiiZYTliEBFn10VSCfo3x531GAmZWsWknoXHQQE1f7P8iE/LByy63Ig8
# YQ0E/HcQq4Nayz/uq0lvIgIhmS81SBmO11Sm0Tr9gEFtuO2co7ZZZL67GOFIDp0O
# Gs+WqOqMmiAhV90qk5F0gZGpdsrgm51lLphnDKBxYJcxXKIkiWfQEM9jyPCi0kxh
# G8uUAhkwXrk0lRN4yxiZQdJS2Y3PazMNd+pb73gDixt3er8NHSbao870WaoRISTI
# MjFlgD0L6/bgx1Abs0zLOdnCb6RoiH6Jg6X82nmSbA+CtxTwCXWaCyCjvyid/YsM
# xHf9C8hZisqXV8EF1rjCUrPjV0XB7yuJHpNGn9UkW1qR6I+ehhxSVgZqg5Yhy/F4
# 1SoKM51xXkYsNti4hOqsfa6Ca7m2gcKUVoWexcnogTOfvSUO1FoScQpEZ7w+6qVU
# +Ts=
# SIG # End signature block
