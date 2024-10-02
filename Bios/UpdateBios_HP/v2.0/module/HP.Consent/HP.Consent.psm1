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


enum TelemetryManagedBy
{
  User = 0
  Organization = 1
}

enum TelemetryPurpose
{
  Marketing = 1
  Support = 2
  ProductEnhancement = 3

}


$ConsentPath = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\HP\Consent'


<#
.SYNOPSIS
  Retrieves the current configured HP Analytics reporting configuration

.DESCRIPTION
    This command retrieves the configuration of the HP Analytics client. The returned object contains the following fields:
    
    - ManagedBy: 'User' (self-managed) or 'Organization' (IT managed)
    - AllowedCollectionPurposes: A collection of allowed purposes, one or more of:
        - Marketing: Analytics are allowed for Marketing purposes
        - Support: Analytics are allowed for Support purposes
        - ProductEnhancement: Analytics are allowed for Product Enhancement purposes
    - TenantID: An organization-configured tenant ID. This is an optional GUID defined by the IT Administrator. If not defined, the TenantID will default to 'Individual'.

.EXAMPLE
    PS C:\> Get-HPAnalyticsConsentConfiguration

    Name                           Value
    ----                           -----
    ManagedBy                      User
    AllowedCollectionPurposes      {Marketing}
    TenantID                       Individual


.LINK
  [Set-HPAnalyticsConsentTenantID](https://developers.hp.com/hp-client-management/doc/Set-HPAnalyticsConsentTenantID)

.LINK
    [Set-HPAnalyticsConsentAllowedPurposes](https://developers.hp.com/hp-client-management/doc/Set-HPAnalyticsConsentAllowedPurposes)

.LINK
  [Set-HPAnalyticsConsentDeviceOwnership](https://developers.hp.com/hp-client-management/doc/Set-HPAnalyticsConsentDeviceOwnership)

.LINK
  For a discussion of these settings, see [https://ftp.hp.com/pub/caps-softpaq/cmit/whitepapers/ManagingConsentforHPAnalytics.pdf](https://ftp.hp.com/pub/caps-softpaq/cmit/whitepapers/ManagingConsentforHPAnalytics.pdf) 

#>
function Get-HPAnalyticsConsentConfiguration
{
  [CmdletBinding(HelpUri = "https://developers.hp.com/hp-client-management/doc/Get-HPAnalyticsConsentConfiguration")]
  param()

  $obj = [ordered]@{
    ManagedBy = [TelemetryManagedBy]"User"
    AllowedCollectionPurposes = [TelemetryPurpose[]]@()
    TenantID = "Individual"
  }

  if (Test-Path $ConsentPath)
  {
    $key = Get-ItemProperty $ConsentPath
    if ($key) {
      if ($key.Managed -eq "True") { $obj.ManagedBy = "Organization" }

      [TelemetryPurpose[]]$purpose = @()
      if ($key.AllowMarketing -eq "Accepted") { $purpose += "Marketing" }
      if ($key.AllowSupport -eq "Accepted") { $purpose += "Support" }
      if ($key.AllowProductEnhancement -eq "Accepted") { $purpose += "ProductEnhancement" }

      ([TelemetryPurpose[]]$obj.AllowedCollectionPurposes) = $purpose
      if ($key.TenantID) {
        $obj.TenantID = $key.TenantID
      }

    }


  }
  else {
    Write-Verbose 'Consent registry key does not exist.'
  }
  $obj
}

<#
.SYNOPSIS
    Sets the ManagedBy (ownership) of a device for the purpose of HP Analytics reporting
 
.DESCRIPTION
    This command configures HP Analytics ownership value to either 'User' or 'Organization'.

    - User: This device is managed by the end user
    - Organization: This device is managed by an organization's IT administrator

.PARAMETER Owner
  Specifies User or Organization as the owner of the device

.EXAMPLE
    # Sets the device to be owned by a User
    PS C:\> Set-HPAnalyticsConsentDeviceOwnership -Owner User

.EXAMPLE
    # Sets the device to be owned by an Organization
    PS C:\> Set-HPAnalyticsConsentDeviceOwnership -Owner Organization


.LINK
  [Get-HPAnalyticsConsentConfiguration](https://developers.hp.com/hp-client-management/doc/Get-HPAnalyticsConsentConfiguration)

.LINK
  [Set-HPAnalyticsConsentTenantID](https://developers.hp.com/hp-client-management/doc/Set-HPAnalyticsConsentTenantID)

.LINK
    [Set-HPAnalyticsConsentAllowedPurposes](https://developers.hp.com/hp-client-management/doc/Set-HPAnalyticsConsentAllowedPurposes)


.LINK
  For a discussion of these settings, see [https://ftp.hp.com/pub/caps-softpaq/cmit/whitepapers/ManagingConsentforHPAnalytics.pdf](https://ftp.hp.com/pub/caps-softpaq/cmit/whitepapers/ManagingConsentforHPAnalytics.pdf) 

.NOTES
  This command requires elevated privileges.

#>
function Set-HPAnalyticsConsentDeviceOwnership
{
  [CmdletBinding(HelpUri = "https://developers.hp.com/hp-client-management/doc/Set-HPAnalyticsConsentDeviceOwnership")]
  param(
    [Parameter(Mandatory = $true,Position = 0)]
    [TelemetryManagedBy]$Owner
  )

  $Managed = ($Owner -eq "Organization")
  New-ItemProperty -Path $ConsentPath -Name "Managed" -Value $Managed -Force | Out-Null

}


<#
.SYNOPSIS
  Sets the Tenant ID of a device for the purpose of HP Analytics reporting

.DESCRIPTION
  This command configures HP Analytics Tenant ID. The Tenant ID is optional and defined by the organization.

  If the Tenant ID is not set, the default value is 'Individual'.

.PARAMETER UUID
  Sets the UUID to the specified GUID. If the TenantID is already configured, the operation will fail unless the -Force parameter is also specified.

.PARAMETER NewUUID
  Sets the UUID to an auto-generated UUID. If the TenantID is already configured, the operation will fail unless the -Force parameter is also specified.

.PARAMETER None
  If specified, this command will remove the TenantID if TenantID is set. TenantID will be set to 'Individual'.

.PARAMETER Force
  If specified, this command will force the Tenant ID to be set even if the Tenant ID is already set. 

.EXAMPLE
  # Sets the tenant ID to a specific UUID
  PS C:\> Set-HPAnalyticsConsentTenantID -UUID 'd34da70b-9d64-47e3-8b3f-9c561df32b98'

.EXAMPLE
  # Sets the tenant ID to an auto-generated UUID
  PS C:\> Set-HPAnalyticsConsentTenantID -NewUUID

.EXAMPLE
  # Removes a configured UUID
  PS C:\> Set-HPAnalyticsConsentTenantID -None

.EXAMPLE
  # Sets (and overwrites) an existing UUID with a new one
  PS C:\> Set-HPAnalyticsConsentTenantID -NewUUID -Force

.LINK
  [Get-HPAnalyticsConsentConfiguration](https://developers.hp.com/hp-client-management/doc/Get-HPAnalyticsConsentConfiguration)

.LINK
  [Set-HPAnalyticsConsentAllowedPurposes](https://developers.hp.com/hp-client-management/doc/Set-HPAnalyticsConsentAllowedPurposes)

.LINK
  [Set-HPAnalyticsConsentDeviceOwnership](https://developers.hp.com/hp-client-management/doc/Set-HPAnalyticsConsentDeviceOwnership)

.LINK
  For a discussion of these settings, see [https://ftp.hp.com/pub/caps-softpaq/cmit/whitepapers/ManagingConsentforHPAnalytics.pdf](https://ftp.hp.com/pub/caps-softpaq/cmit/whitepapers/ManagingConsentforHPAnalytics.pdf) 

.NOTES
  This command requires elevated privileges.

#>
function Set-HPAnalyticsConsentTenantID
{
  [CmdletBinding(DefaultParameterSetName = "SpecificUUID",HelpUri = "https://developers.hp.com/hp-client-management/doc/Set-HPAnalyticsConsentTenantID")]
  param(
    [Parameter(ParameterSetName = 'SpecificUUID',Mandatory = $true,Position = 0)]
    [guid]$UUID,
    [Parameter(ParameterSetName = 'NewUUID',Mandatory = $true,Position = 0)]
    [switch]$NewUUID,
    [Parameter(ParameterSetName = 'None',Mandatory = $true,Position = 0)]
    [switch]$None,
    [Parameter(ParameterSetName = 'SpecificUUID',Mandatory = $false,Position = 1)]
    [Parameter(ParameterSetName = 'NewUUID',Mandatory = $false,Position = 1)]
    [switch]$Force
  )

  if ($NewUUID.IsPresent)
  {
    $uid = [guid]::NewGuid()
  }
  elseif ($None.IsPresent) {
    $uid = "Individual"
  }
  else {
    $uid = $UUID
  }

  if ((-not $Force.IsPresent) -and (-not $None.IsPresent))
  {

    $config = Get-HPAnalyticsConsentConfiguration -Verbose:$VerbosePreference
    if ($config.TenantID -and $config.TenantID -ne "Individual" -and $config.TenantID -ne $uid)
    {

      Write-Verbose "Tenant ID $($config.TenantID) is already configured"
      throw [ArgumentException]"A Tenant ID is already configured for this device. Use -Force to overwrite it."
    }
  }
  New-ItemProperty -Path $ConsentPath -Name "TenantID" -Value $uid -Force | Out-Null
}



<#
.SYNOPSIS
  Sets the allowed reporting purposes for HP Analytics
 
.DESCRIPTION
    This command configures how HP may use the data reported. The allowed purposes are: 

    - Marketing: The data may be used for marketing purposes.
    - Support: The data may be used for support purposes.
    - ProductEnhancement: The data may be used for product enhancement purposes.

    Note that you may supply any combination of the above purpose in a single command. Any of the purposes not included
    in the list will be explicitly rejected.


.PARAMETER AllowedPurposes
    Specifies a list of allowed purposes for the reported data. The value must be one (or more) of the following values: 
    - Marketing
    - Support
    - ProductEnhancement

    The purposes included in this list will be explicitly accepted. The purposes not included in this list will be explicitly rejected.

.PARAMETER None
    If specified, this command rejects all purposes. 


.EXAMPLE
    # Accepts all purposes
    PS C:\> Set-HPAnalyticsConsentAllowedPurposes  -AllowedPurposes Marketing,Support,ProductEnhancement

.EXAMPLE
    # Sets ProductEnhancement, rejects everything else
    PS C:\> Set-HPAnalyticsConsentAllowedPurposes  -AllowedPurposes ProductEnhancement

.EXAMPLE
    # Rejects all purposes
    PS C:\> Set-HPAnalyticsConsentAllowedPurposes  -None
    

.LINK
  [Get-HPAnalyticsConsentConfiguration](https://developers.hp.com/hp-client-management/doc/Get-HPAnalyticsConsentConfiguration)

.LINK
  [Set-HPAnalyticsConsentTenantID](https://developers.hp.com/hp-client-management/doc/Set-HPAnalyticsConsentTenantID)

.LINK
  [Set-HPAnalyticsConsentDeviceOwnership](https://developers.hp.com/hp-client-management/doc/Set-HPAnalyticsConsentDeviceOwnership)

.LINK
  For a discussion of these settings, see [https://ftp.hp.com/pub/caps-softpaq/cmit/whitepapers/ManagingConsentforHPAnalytics.pdf](https://ftp.hp.com/pub/caps-softpaq/cmit/whitepapers/ManagingConsentforHPAnalytics.pdf) 

.NOTES
  This command requires elevated privileges.

#>
function Set-HPAnalyticsConsentAllowedPurposes
{
  [CmdletBinding(DefaultParameterSetName = "SpecificPurposes",HelpUri = "https://developers.hp.com/hp-client-management/doc/Set-HPAnalyticsConsentAllowedPurposes")]
  param(
    [Parameter(ParameterSetName = 'SpecificPurposes',Mandatory = $true,Position = 0)]
    [TelemetryPurpose[]]$AllowedPurposes,
    [Parameter(ParameterSetName = 'NoPurpose',Mandatory = $true,Position = 0)]
    [switch]$None
  )

  if ($None.IsPresent)
  {
    Write-Verbose "Clearing all opt-in telemetry purposes"
    New-ItemProperty -Path $ConsentPath -Name "AllowMarketing" -Value "Rejected" -Force | Out-Null
    New-ItemProperty -Path $ConsentPath -Name "AllowSupport" -Value "Rejected" -Force | Out-Null
    New-ItemProperty -Path $ConsentPath -Name "AllowProductEnhancement" -Value "Rejected" -Force | Out-Null

  }
  else {
    $allowed = $AllowedPurposes | ForEach-Object {
      New-ItemProperty -Path $ConsentPath -Name "Allow$_" -Value 'Accepted' -Force | Out-Null
      $_
    }

    if ($allowed -notcontains 'Marketing') {
      New-ItemProperty -Path $ConsentPath -Name "AllowMarketing" -Value "Rejected" -Force | Out-Null
    }
    if ($allowed -notcontains 'Support') {
      New-ItemProperty -Path $ConsentPath -Name "AllowSupport" -Value "Rejected" -Force | Out-Null
    }
    if ($allowed -notcontains 'ProductEnhancement') {
      New-ItemProperty -Path $ConsentPath -Name "AllowProductEnhancement" -Value "Rejected" -Force | Out-Null
    }

  }

}


# SIG # Begin signature block
# MIIoHgYJKoZIhvcNAQcCoIIoDzCCKAsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCATeVoRiH3RLu0v
# 97OVZbAaz5G7tOMw4IxwUQP1qS6fjKCCDYowggawMIIEmKADAgECAhAIrUCyYNKc
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
# KwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIFiCldSk
# UzCm5njIqst4NcCcbLXnpa5wZhXOK8ui21EKMA0GCSqGSIb3DQEBAQUABIIBgBAS
# v780/RVgrlIQps7WS5WQqrZkJ3nWGmcnOeu+0FXI2GnUaytg3OUEvDLu93TzycoC
# +xsR2g0P4MIagTlEKI3lUi2JISN0ZuPENmEBgsLdQIs6qOF7U2m8EmhcPksTcNZg
# thXJxgJDCzLRSwOT19k0lM/5uO4aSbORakeERjd+KsDhHlvidmvPO+QCe4Ut56Ns
# PNDwGHaJpquKOtRPd01qcBuqaxQf/pUw6YGzzmqxSToV9QgP6VYSSZFHi8B9vAcL
# xK8ry+5PJfNKTaBRVG2SqpH8VpZq+fkRbciMXUio8tgTe9Vys7JDMWRFdyxS4ZBI
# ktwSramWYP7/FNSRWLJPcYbP7aMX3T8lCgK47GDb+hpQMCe7D4M84nvvYTy9Q7oX
# rPpsSiMLno58fnpGUljfQZqTEWPq6IxvZ/jDMmaCgBifkai64U7lk4/vInrgGzlr
# Srw00PYxUK7cku99MeidlsyAicF4FhW4L3j85+ssy27w5mapE0yLmx26gVyxr6GC
# F0Awghc8BgorBgEEAYI3AwMBMYIXLDCCFygGCSqGSIb3DQEHAqCCFxkwghcVAgED
# MQ8wDQYJYIZIAWUDBAIBBQAweAYLKoZIhvcNAQkQAQSgaQRnMGUCAQEGCWCGSAGG
# /WwHATAxMA0GCWCGSAFlAwQCAQUABCCdUR4r8anLuJtKDvfCJlHmzNj77NilHAtK
# 1Di7ImHjuQIRAN/Spz4HRNIq4L5dGwPYBe8YDzIwMjQwODI3MTY1NTUwWqCCEwkw
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
# CQQxIgQgPUd1+yk88irJPvcAm4+ftQq+3ymhm+Ar0HhDQ+mo8tQwNwYLKoZIhvcN
# AQkQAi8xKDAmMCQwIgQg0vbkbe10IszR1EBXaEE2b4KK2lWarjMWr00amtQMeCgw
# DQYJKoZIhvcNAQEBBQAEggIAbu2OOdlNPOxNbPnMHJzDppsYbS3HekzAAC/kFkVO
# joh2XCPViKtF+5MAp3V8KZ0lsKYT/qZUibjM+aMFo93aJCosvjr/pEB93gVM0/bZ
# th+RW6oDqXX3Ea4FYKcrSZYHtO/xBysZI8oQF84pG9tAMfX1gXZiUR8BT4fHPPad
# 0+ZfCJNhUiL4Pa6RBGwaZfHPP4tUryPeazaKJGu67D3ZpJWiXw0ooBwX0rH99Z4b
# OjipRcrUHwkueO5GNcINU+1y8Vj5e137fG4I7ec+JHye+6GFufYoq32eWHssnmkE
# DjxM4+2+i0QG89mG4UVt14I5CQXoEC0ZIw80kBNxoycbkCDkbqczrPCte422gAhF
# LiFquQIqriU4oG91wG3DeTu+FnX0PYJV8FyIa7zNqye2QGEQtsIM6kT7GhrfPPQZ
# VpROrqR9iMM6sqoeOdaimUJtBELPKSItXmDYAKJtQAxSXN27DilXuWu0r10YzDYF
# 6yAq2jC9i2Oujbmmi4srQsypof4g7EMeHIlqdc/FbmczgzIxMjDNMJZbNgc7d3VM
# V+N0bqnjG6Rlnn0sDDaF/dQhp5PQNDMD2pt9hCbDK1+iR2cff+MQM29aQse77laP
# kjLfrSiyNA7szznRKUvzCGFS3rd8ZWVqhnzsEbhlVxzf33n6tAAIwr+nIwMgQbYU
# uCk=
# SIG # End signature block
