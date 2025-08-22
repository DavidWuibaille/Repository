#
#  Copyright 2018-2024 HP Development Company, L.P.
#  All Rights Reserved.
#
# NOTICE:  All information contained herein is, and remains the property of HP Inc.
#
# The intellectual and technical concepts contained herein are proprietary to HP Inc
# and may be covered by U.S. and Foreign Patents, patents in process, and are protected by
# trade secret or copyright law. Dissemination of this information or reproduction of this material
# is strictly forbidden unless prior written permission is obtained from HP Inc.

using namespace HP.CMSLHelper

Set-StrictMode -Version 3.0
$ErrorActionPreference = "Stop"
#requires -Modules "HP.Private"

# CMSL is normally installed in C:\Program Files\WindowsPowerShell\Modules
# but if installed via PSGallery and via PS7, it is installed in a different location
if (Test-Path "$PSScriptRoot\..\HP.Private\HP.CMSLHelper.dll") {
  Add-Type -Path "$PSScriptRoot\..\HP.Private\HP.CMSLHelper.dll"
}
else{
  Add-Type -Path "$PSScriptRoot\..\..\HP.Private\1.7.2\HP.CMSLHelper.dll"
}

<#
.SYNOPSIS
  Retrieves the HP Secure Platform Management state

.DESCRIPTION
  This command retrieves the state of the HP Secure Platform Management.

.LINK
  [Blog post: HP Secure Platform Management with the HP Client Management Script Library](https://developers.hp.com/hp-client-management/blog/hp-secure-platform-management-hp-client-management-script-library)

.NOTES
  - Requires HP BIOS with Secure Platform Management support.
  - This command requires elevated privileges.

.EXAMPLE
  Get-HPSecurePlatformState
#>
function Get-HPSecurePlatformState {
  [CmdletBinding(HelpUri = "https://developers.hp.com/hp-client-management/doc/Get-HPSecurePlatformState")]
  param()
  $mi_result = 0
  $data = New-Object -TypeName provisioning_data_t
  $c = '[DfmNativeSecurePlatform]::get_secureplatform_provisioning' + (Test-OSBitness) + '([ref]$data,[ref]$mi_result);'
  $result = Invoke-Expression -Command $c
  Test-HPPrivateCustomResult -result $result -mi_result $mi_result -Category 0x04

  $kek_mod = $data.kek_mod
  [array]::Reverse($kek_mod)

  $sk_mod = $data.sk_mod
  [array]::Reverse($sk_mod)

  # calculating EndorsementKeyID
  $kek_encoded = [System.Convert]::ToBase64String($kek_mod)
  # $kek_decoded = [Convert]::FromBase64String($kek_encoded)
  # $kek_hash = Get-HPPrivateHash -Data $kek_decoded
  # $kek_Id = [System.Convert]::ToBase64String($kek_hash)

  # calculating SigningKeyID
  $sk_encoded = [System.Convert]::ToBase64String($sk_mod)
  # $sk_decoded = [Convert]::FromBase64String($sk_encoded)
  # $sk_hash = Get-HPPrivateHash -Data $sk_decoded
  # $sk_Id = [System.Convert]::ToBase64String($sk_hash)

  # get Sure Admin Mode and Local Access values
  $sure_admin_mode = ""
  $local_access = ""
  if ((Get-HPPrivateIsSureAdminSupported) -eq $true) {
    $sure_admin_state = Get-HPSureAdminState
    $sure_admin_mode = $sure_admin_state.SureAdminMode
    $local_access = $sure_admin_state.LocalAccess
  }

  # calculate FeaturesInUse
  $featuresInUse = ""
  if ($data.features_in_use -eq "SureAdmin") {
    $featuresInUse = "SureAdmin ($sure_admin_mode, Local Access - $local_access)"
  }
  else {
    $featuresInUse = $data.features_in_use
  }

  $obj = [ordered]@{
    State = $data.State
    Version = "$($data.subsystem_version[0]).$($data.subsystem_version[1])"
    Nonce = $($data.arp_counter)
    FeaturesInUse = $featuresInUse
    EndorsementKeyMod = $kek_mod
    SigningKeyMod = $sk_mod
    EndorsementKeyID = $kek_encoded
    SigningKeyID = $sk_encoded
  }
  return New-Object -TypeName PSCustomObject -Property $obj
}


<#
.SYNOPSIS
  Creates an HP Secure Platform Management payload to provision a _Key Endorsement_ key

.DESCRIPTION
  This command creates an HP Secure Platform Management payload to provision a _Key Endorsement_ key. The purpose of the endorsement key is to protect the signing key against unauthorized changes.
  Only holders of the key endorsement private key may change the signing key.

  There are three endorsement options to choose from:
  - Endorsement Key File (and Password) using -EndorsementKeyFile and -EndorsementKeyPassword parameters 
  - Endorsement Key Certificate using -EndorsementKeyCertificate parameter
  - Remote Endorsement using -RemoteEndorsementKeyID and -RemoteSigningServiceURL parameters 

  Please note that using a Key File with Password in PFX format is recommended over using an X509 Certificate object because a private key in a certificate is not password protected.

  This command writes the created payload to the pipeline or to the file specified in the OutputFile parameter.
  This payload can then be passed to the Set-HPSecurePlatformPayload command.

  Security note: Payloads should only be created on secure servers. Once created, the payload may be transferred to a client and applied via the Set-HPSecurePlatformPayload command. Creating the payload and passing it to the Set-HPSecurePlatformPayload command via the pipeline is not a recommended production pattern.

.PARAMETER EndorsementKeyFile
  Specifies the _Key Endorsement_ key certificate as a PFX (PKCS #12) file

.PARAMETER EndorsementKeyPassword
  Specifies the password for the _Endorsement Key_ PFX file. If no password was used when the PFX was created (not recommended), this parameter may be omitted.

.PARAMETER EndorsementKeyCertificate
  Specifies the endorsement key certificate as an X509Certificate object

.PARAMETER BIOSPassword
  Specifies the BIOS setup password, if any. Note that the password will be in the clear in the generated payload.

.PARAMETER OutputFile
  Specifies the file to write output to instead of writing the output to the pipeline

.PARAMETER RemoteEndorsementKeyID
  Specifies the Endorsement Key ID to be used

.PARAMETER RemoteSigningServiceURL
  Specifies the Key Management Services (KMS) server URL (I.e.: https://<KMSAppName>.azurewebsites.net/). This URL must be https. 

.PARAMETER CacheAccessToken
  If specified, the access token is cached in msalcache.dat file and user credentials will not be asked again until the credentials expire.
  This parameter should be specified for caching the access token when performing multiple operations on the KMS server. 
  If access token is not cached, the user must re-enter credentials on each call of this command.

.LINK
  [Blog post: HP Secure Platform Management with the HP Client Management Script Library](https://developers.hp.com/hp-client-management/blog/hp-secure-platform-management-hp-client-management-script-library)

.NOTES
  The Key Endorsement private key must never leave a secure server. The payload must be created on a secure server, then may be transferred to a client.

  - Requires HP BIOS with Secure Platform Management support.

.EXAMPLE
   $payload = New-HPSecurePlatformEndorsementKeyProvisioningPayload -EndorsementKeyFile "$path\endorsement_key.pfx"
   ...
   $payload | Set-HPSecurePlatformPayload

#>
function New-HPSecurePlatformEndorsementKeyProvisioningPayload {
  [CmdletBinding(DefaultParameterSetName = "EK_FromFile",HelpUri = "https://developers.hp.com/hp-client-management/doc/New-HPSecurePlatformEndorsementKeyProvisioningPayload")]
  param(
    [Parameter(ParameterSetName = "EK_FromFile",Mandatory = $true,Position = 0)]
    [System.IO.FileInfo]$EndorsementKeyFile,

    [Parameter(ParameterSetName = "EK_FromFile",Mandatory = $false,Position = 1)]
    [string]$EndorsementKeyPassword,

    [Parameter(ParameterSetName = "EK_FromBytes",Mandatory = $true,Position = 0)]
    [System.Security.Cryptography.X509Certificates.X509Certificate2]$EndorsementKeyCertificate,

    [Parameter(ParameterSetName = "EK_FromFile",Mandatory = $false,Position = 2)]
    [Parameter(ParameterSetName = "EK_FromBytes",Mandatory = $false,Position = 2)]
    [Parameter(ParameterSetName = "RemoteSigning",Mandatory = $false,Position = 0)]
    [string]$BIOSPassword,

    [Parameter(ParameterSetName = "EK_FromFile",Mandatory = $false,Position = 3)]
    [Parameter(ParameterSetName = "EK_FromBytes",Mandatory = $false,Position = 3)]
    [System.IO.FileInfo]$OutputFile,

    [Parameter(ParameterSetName = "RemoteSigning",Mandatory = $true,Position = 1)]
    [string]$RemoteEndorsementKeyID,

    [Parameter(ParameterSetName = "RemoteSigning",Mandatory = $true,Position = 2)]
    [string]$RemoteSigningServiceURL,

    [Parameter(ParameterSetName = "RemoteSigning",Mandatory = $false,Position = 3)]
    [switch]$CacheAccessToken
  )

  # only allow https or file paths with or without file:// URL prefix
  if ($RemoteSigningServiceURL -and -not ($RemoteSigningServiceURL.StartsWith("https://",$true,$null) -or [System.IO.Directory]::Exists($RemoteSigningServiceURL) -or $RemoteSigningServiceURL.StartsWith("file://",$true,$null))) {
    throw [System.ArgumentException]"Only HTTPS or valid existing directory paths are supported."
  }

  if ($PSCmdlet.ParameterSetName -eq "RemoteSigning") {
    if (-not $RemoteSigningServiceURL.EndsWith('/')) {
      $RemoteSigningServiceURL += '/'
    }
    $RemoteSigningServiceURL += 'api/commands/p21ekpubliccert'
    $jsonPayload = New-HPPrivateRemoteSecurePlatformProvisioningJson -EndorsementKeyID $RemoteEndorsementKeyID
    $accessToken = Get-HPPrivateSureAdminKMSAccessToken -CacheAccessToken:$CacheAccessToken
    $response,$responseContent = Send-HPPrivateKMSRequest -KMSUri $RemoteSigningServiceURL -JsonPayload $jsonPayload -AccessToken $accessToken -Verbose:$VerbosePreference
  
    if ($response -eq "OK") {
      $crt = [Convert]::FromBase64String($responseContent)
    }
    else {
      Invoke-HPPrivateKMSErrorHandle -ApiResponseContent $responseContent -Status $response
    }
  }
  else {
    $crt = (Get-HPPrivateX509CertCoalesce -File $EndorsementKeyFile -cert $EndorsementKeyCertificate -password $EndorsementKeyPassword -Verbose:$VerbosePreference).Certificate
  }

  Write-Verbose "Creating EK provisioning payload"
  if ($BIOSPassword) {
    $passwordLength = $BIOSPassword.Length
  }
  else {
    $passwordLength = 0
  }

  $opaque = New-Object opaque4096_t
  $opaqueLength = 4096
  $mi_result = 0
  $cmd = '[DfmNativeSecurePlatform]::get_ek_provisioning_data' + (Test-OSBitness) + '($crt,$($crt.Count),$BIOSPassword, $passwordLength, [ref]$opaque, [ref]$opaqueLength,  [ref]$mi_result);'
  $result = Invoke-Expression -Command $cmd
  Test-HPPrivateCustomResult -result $result -mi_result $mi_result -Category 0x04

  $output = New-Object -TypeName PortableFileFormat
  $output.Data = $opaque.raw[0..($opaqueLength - 1)]
  $output.purpose = "hp:provision:endorsementkey"
  $output.timestamp = Get-Date

  if ($OutputFile) {
    Write-Verbose "Will output to file $OutputFile"
    $f = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputFile)
    $output | ConvertTo-Json -Compress | Out-File $f -Encoding utf8
  }
  else {
    $output | ConvertTo-Json -Compress
  }
}


<#
.SYNOPSIS
  Creates an HP Secure Platform Management payload to provision a _Signing Key_ key

.DESCRIPTION
  This command creates an HP Secure Platform Management payload to provision a _Signing Key_ key. The purpose of the signing key is to sign commands for the Secure Platform Management. The Signing key is protected by the endorsement key. As a result, the endorsement key private key must be available when provisioning or changing the signing key.
  There are three signing options to choose from:
  - Signing Key File (and Password) using -SigningKeyFile and -SigningKeyPassword parameters 
  - Signing Key Certificate using -SigningKeyCertificate parameter
  - Remote Signing using -RemoteSigningServiceKeyID and -RemoteSigningServiceURL parameters 

  There are three endorsement options to choose from:
  - Endorsement Key File (and Password) using -EndorsementKeyFile and -EndorsementKeyPassword parameters 
  - Endorsement Key Certificate using -EndorsementKeyCertificate parameter
  - Remote Endorsement using -RemoteEndorsementKeyID and -RemoteSigningServiceURL parameters 

  Please note that using a Key File with Password in PFX format is recommended over using an X509 Certificate object because a private key in a certificate is not password protected.

  This command writes the created payload to the pipeline or to the file specified in the -OutputFile parameter. This payload can then be passed to the Set-HPSecurePlatformPayload command.

  Security note: Payloads should only be created on secure servers. Once created, the payload may be transferred to a client and applied via the Set-HPSecurePlatformPayload command. Please note that creating the payload and passing it to the Set-HPSecurePlatformPayload command via the pipeline is not a recommended production pattern.

.PARAMETER EndorsementKeyFile
  Specifies the _Key Endorsement_ key certificate as a PFX (PKCS #12) file

.PARAMETER EndorsementKeyPassword
  Specifies the password for the _Endorsement Key_ PFX file. If no password was used when the PFX was created (which is not recommended), this parameter may be omitted.

.PARAMETER EndorsementKeyCertificate
  Specifies the endorsement key certificate as an X509Certificate object

.PARAMETER SigningKeyFile
  Specifies the path to the Secure Platform Management signing key as a PFX file. If the PFX file is protected by a password (recommended), the SigningKeyPassword parameter should also be provided.

.PARAMETER SigningKeyCertificate
  Specifies the Secure Platform Management signing key certificate as an X509Certificate object

.PARAMETER SigningKeyPassword
  Specifies the Secure Platform Management signing key file password, if required.

.PARAMETER Nonce
  Specifies a Nonce. If nonce is specified, the Secure Platform Management subsystem will only accept commands with a nonce greater or equal to the last nonce sent. This approach helps to prevent replay attacks. If not specified, the nonce is inferred from the current local time. The current local time as the nonce works in most cases. However, this approach has a resolution of seconds, so when performing parallel operations or a high volume of operations, it is possible for the same counter to be interpreted for more than one command. In these cases, the caller should use its own nonce derivation and provide it through this parameter.

.PARAMETER OutputFile
  Specifies the file to write output to instead of writing the output to the pipeline

.PARAMETER RemoteEndorsementKeyID
  Specifies the Endorsement Key ID to be used

.PARAMETER RemoteSigningKeyID
  Specifies the Signing Key ID to be provisioned

.PARAMETER RemoteSigningServiceURL
  Specifies the (Key Management Service) KMS server URL (I.e.: https://<KMSAppName>.azurewebsites.net/). This URL must be https. 

.PARAMETER CacheAccessToken
  If specified, the access token is cached in msalcache.dat file and user credentials will not be asked again until the credentials expire.
  This parameter should be specified for caching the access token when performing multiple operations on the KMS server. 
  If access token is not cached, the user must re-enter credentials on each call of this command.

.LINK
  [Blog post: HP Secure Platform Management with the HP Client Management Script Library](https://developers.hp.com/hp-client-management/blog/hp-secure-platform-management-hp-client-management-script-library)

.NOTES
  - Requires HP BIOS with Secure Platform Management support.

.EXAMPLE
  $payload = New-HPSecurePlatformSigningKeyProvisioningPayload -EndorsementKeyFile "$path\endorsement_key.pfx"  `
               -SigningKeyFile "$path\signing_key.pfx"
  ...
  $payload | Set-HPSecurePlatformPayload

#>
function New-HPSecurePlatformSigningKeyProvisioningPayload {
  [CmdletBinding(DefaultParameterSetName = "EF_SF",HelpUri = "https://developers.hp.com/hp-client-management/doc/New-HPSecurePlatformSigningKeyProvisioningPayload")]
  param(
    [Parameter(ParameterSetName = "EF_SF",Mandatory = $true,Position = 0)]
    [Parameter(ParameterSetName = "EF_SB",Mandatory = $true,Position = 0)]
    [System.IO.FileInfo]$EndorsementKeyFile,

    [Parameter(ParameterSetName = "EF_SF",Mandatory = $false,Position = 1)]
    [Parameter(ParameterSetName = "EF_SB",Mandatory = $false,Position = 1)]
    [string]$EndorsementKeyPassword,

    [Parameter(ParameterSetName = "EF_SF",Mandatory = $false,Position = 2)]
    [Parameter(ParameterSetName = "EB_SF",Mandatory = $false,Position = 2)]
    [System.IO.FileInfo]$SigningKeyFile,

    [Parameter(ParameterSetName = "EF_SF",Mandatory = $false,Position = 3)]
    [Parameter(ParameterSetName = "EB_SF",Mandatory = $false,Position = 3)]
    [string]$SigningKeyPassword,

    [Parameter(ParameterSetName = "EB_SF",Mandatory = $true,Position = 0)]
    [Parameter(ParameterSetName = "EB_SB",Mandatory = $true,Position = 0)]
    [System.Security.Cryptography.X509Certificates.X509Certificate2]$EndorsementKeyCertificate,

    [Parameter(ValueFromPipeline = $true,ParameterSetName = "EB_SB",Mandatory = $false,Position = 2)]
    [Parameter(ValueFromPipeline = $true,ParameterSetName = "EF_SB",Mandatory = $false,Position = 2)]
    [System.Security.Cryptography.X509Certificates.X509Certificate2]$SigningKeyCertificate,

    [Parameter(ParameterSetName = "EF_SF",Mandatory = $false,Position = 4)]
    [Parameter(ParameterSetName = "EB_SF",Mandatory = $false,Position = 4)]
    [Parameter(ParameterSetName = "EF_SB",Mandatory = $false,Position = 4)]
    [Parameter(ParameterSetName = "EB_SB",Mandatory = $false,Position = 4)]
    [Parameter(ParameterSetName = "RemoteSigning",Mandatory = $false,Position = 1)]
    [uint32]$Nonce = [math]::Floor([decimal](Get-Date (Get-Date).ToUniversalTime() -UFormat "%s").Replace(',','.')),

    [Parameter(ParameterSetName = "EF_SF",Mandatory = $false,Position = 5)]
    [Parameter(ParameterSetName = "EB_SF",Mandatory = $false,Position = 5)]
    [Parameter(ParameterSetName = "EF_SB",Mandatory = $false,Position = 5)]
    [Parameter(ParameterSetName = "EB_SB",Mandatory = $false,Position = 5)]
    [Parameter(ParameterSetName = "RemoteSigning",Mandatory = $false,Position = 2)]
    [System.IO.FileInfo]$OutputFile,

    [Parameter(ParameterSetName = "RemoteSigning",Mandatory = $true,Position = 3)]
    [string]$RemoteEndorsementKeyID,

    [Parameter(ParameterSetName = "RemoteSigning",Mandatory = $false,Position = 4)]
    [string]$RemoteSigningKeyID,

    [Parameter(ParameterSetName = "RemoteSigning",Mandatory = $true,Position = 5)]
    [string]$RemoteSigningServiceURL,

    [Parameter(ParameterSetName = "RemoteSigning",Mandatory = $false,Position = 6)]
    [switch]$CacheAccessToken
  )

  # only allow https or file paths with or without file:// URL prefix
  if ($RemoteSigningServiceURL -and -not ($RemoteSigningServiceURL.StartsWith("https://",$true,$null) -or [System.IO.Directory]::Exists($RemoteSigningServiceURL) -or $RemoteSigningServiceURL.StartsWith("file://",$true,$null))) {
    throw [System.ArgumentException]"Only HTTPS or valid existing directory paths are supported."
  }

  if ($PSCmdlet.ParameterSetName -eq "RemoteSigning") {
    if (-not $RemoteSigningServiceURL.EndsWith('/')) {
      $RemoteSigningServiceURL += '/'
    }
    $RemoteSigningServiceURL += 'api/commands/p21skprovisioningpayload'

    $params = @{
      EndorsementKeyID = $RemoteEndorsementKeyID
      Nonce = $Nonce
    }
    if ($RemoteSigningKeyID) {
      $params.SigningKeyID = $RemoteSigningKeyID
    }

    $jsonPayload = New-HPPrivateRemoteSecurePlatformProvisioningJson @params
    $accessToken = Get-HPPrivateSureAdminKMSAccessToken -CacheAccessToken:$CacheAccessToken
    $response,$responseContent = Send-HPPrivateKMSRequest -KMSUri $RemoteSigningServiceURL -JsonPayload $jsonPayload -AccessToken $accessToken -Verbose:$VerbosePreference
  
    if ($response -eq "OK") {
      return $responseContent
    }
    else {
      Invoke-HPPrivateKMSErrorHandle -ApiResponseContent $responseContent -Status $response
    }
  }
  else {
    $ek = Get-HPPrivateX509CertCoalesce -File $EndorsementKeyFile -password $EndorsementKeyPassword -cert $EndorsementKeyCertificate -Verbose:$VerbosePreference
    $sk = $null
    if ($SigningKeyFile -or $SigningKeyCertificate) {
      $sk = Get-HPPrivateX509CertCoalesce -File $SigningKeyFile -password $SigningKeyPassword -cert $SigningKeyCertificate -Verbose:$VerbosePreference
    }

    Write-Verbose "Creating SK provisioning payload"

    $payload = New-Object sk_provisioning_t
    $sub = New-Object sk_provisioning_payload_t

    $sub.Counter = $nonce
    if ($sk) {
      $sub.mod = $Sk.Modulus
    }
    else {
      Write-Verbose "Assuming deprovisioning due to missing signing key update"
      $sub.mod = New-Object byte[] 256
    }
    $payload.Data = $sub
    Write-Verbose "Using counter value of $($sub.Counter)"
    $out = Convert-HPPrivateObjectToBytes -obj $sub -Verbose:$VerbosePreference
    $payload.sig = Invoke-HPPrivateSignData -Data $out[0] -Certificate $ek.Full -Verbose:$VerbosePreference


    Write-Verbose "Serializing payload"
    $out = Convert-HPPrivateObjectToBytes -obj $payload -Verbose:$VerbosePreference

    $output = New-Object -TypeName PortableFileFormat
    $output.Data = ($out[0])[0..($out[1] - 1)];
    $output.purpose = "hp:provision:signingkey"
    $output.timestamp = Get-Date

    if ($OutputFile) {
      Write-Verbose "Will output to file $OutputFile"
      $f = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputFile)
      $output | ConvertTo-Json -Compress | Out-File -FilePath $f -Encoding utf8
    }
    else {
      $output | ConvertTo-Json -Compress
    }
  }
}

function New-HPPrivateRemoteSecurePlatformProvisioningJson {
  [CmdletBinding()]
  param(
    [Parameter(ParameterSetName = "RemoteSigning",Mandatory = $false,Position = 1)]
    [uint32]$Nonce,

    [Parameter(ParameterSetName = "RemoteSigning",Mandatory = $true,Position = 2)]
    [string]$EndorsementKeyId,

    [Parameter(ParameterSetName = "RemoteSigning",Mandatory = $false,Position = 3)]
    [string]$SigningKeyId
  )

  $payload = [ordered]@{
    EKId = $EndorsementKeyId
  }

  if ($Nonce) {
    $payload['Nonce'] = $Nonce
  }

  if ($SigningKeyId) {
    $payload['SKId'] = $SigningKeyId
  }

  $payload | ConvertTo-Json -Compress
}

<#
.SYNOPSIS
  Creates a deprovisioning payload

.DESCRIPTION
  This command creates a payload to deprovision the HP Secure Platform Management. The caller must have access to the Endorsement Key private key in order to create this payload.

  There are three endorsement options to choose from:
  - Endorsement Key File (and Password) using -EndorsementKeyFile and -EndorsementKeyPassword parameters 
  - Endorsement Key Certificate using -EndorsementKeyCertificate parameter
  - Remote Endorsement using -RemoteEndorsementKeyID and -RemoteSigningServiceURL parameters 
  
  Please note that using a Key File with Password in PFX format is recommended over using an X509 Certificate object because a private key in a certificate is not password protected.

  This command writes the created payload to the pipeline or to the file specified in the -OutputFile parameter. This payload can then be passed to the Set-HPSecurePlatformPayload command.

  Security note: Payloads should only be created on secure servers. Once created, the payload may be transferred to a client and applied via the Set-HPSecurePlatformPayload command. Creating the payload and passing it to the Set-HPSecurePlatformPayload command via the pipeline is not a recommended production pattern.

.PARAMETER EndorsementKeyFile
  Specifies the _Key Endorsement_ key certificate as a PFX (PKCS #12) file

.PARAMETER EndorsementKeyPassword
  The password for the endorsement key certificate file. If no password was used when the PFX was created (which is not recommended), this parameter may be omitted.

.PARAMETER EndorsementKeyCertificate
  Specifies the endorsement key certificate as an X509Certificate object

.PARAMETER Nonce
  Specifies a Nonce. If nonce is specified, the Secure Platform Management subsystem will only accept commands with a nonce greater or equal to the last nonce sent. This approach helps to prevent replay attacks. If not specified, the nonce is inferred from the current local time. The current local time as the nonce works in most cases. However, this approach has a resolution of seconds, so when performing parallel operations or a high volume of operations, it is possible for the same counter to be interpreted for more than one command. In these cases, the caller should use its own nonce derivation and provide it through this parameter.

.PARAMETER RemoteEndorsementKeyID
  Specifies the Endorsement Key ID to be used

.PARAMETER RemoteSigningServiceURL
  Specifies the (Key Management Service) KMS server URL (I.e.: https://<KMSAppName>.azurewebsites.net/). This URL must be https. 

.PARAMETER CacheAccessToken
  If specified, the access token is cached in msalcache.dat file and user credentials will not be asked again until the credentials expire.
  This parameter should be specified for caching the access token when performing multiple operations on the KMS server. 
  If access token is not cached, the user must re-enter credentials on each call of this command.

.LINK
  [Blog post: HP Secure Platform Management with the HP Client Management Script Library](https://developers.hp.com/hp-client-management/blog/hp-secure-platform-management-hp-client-management-script-library)

.PARAMETER OutputFile
  Specifies the file to write output to instead of writing the output to the pipeline

.NOTES
  - Requires HP BIOS with Secure Platform Management support.

.EXAMPLE
  New-HPSecurePlatformDeprovisioningPayload -EndorsementKeyFile kek.pfx | Set-HPSecurePlatformPayload

.EXAMPLE
  New-HPSecurePlatformDeprovisioningPayload -EndorsementKeyFile kek.pfx -OutputFile deprovisioning_payload.dat
#>
function New-HPSecurePlatformDeprovisioningPayload {
  [CmdletBinding(DefaultParameterSetName = "EF",HelpUri = "https://developers.hp.com/hp-client-management/doc/New-HPSecurePlatformDeprovisioningPayload")]
  param(
    [Parameter(ParameterSetName = "EF",Mandatory = $true,Position = 0)]
    [string]$EndorsementKeyFile,

    [Parameter(ParameterSetName = "EF",Mandatory = $false,Position = 1)]
    [string]$EndorsementKeyPassword,

    [Parameter(ParameterSetName = "EF",Mandatory = $false,Position = 2)]
    [Parameter(ParameterSetName = "EB",Mandatory = $false,Position = 2)]
    [Parameter(ParameterSetName = "RemoteSigning",Mandatory = $false,Position = 1)]
    [uint32]$Nonce = [math]::Floor([decimal](Get-Date (Get-Date).ToUniversalTime() -UFormat "%s").Replace(',','.')),

    [Parameter(ParameterSetName = "EB",Mandatory = $true,Position = 0)]
    [System.Security.Cryptography.X509Certificates.X509Certificate2]$EndorsementKeyCertificate,

    [Parameter(ParameterSetName = "EB",Mandatory = $false,Position = 4)]
    [Parameter(ParameterSetName = "EF",Mandatory = $false,Position = 4)]
    [Parameter(ParameterSetName = "RemoteSigning",Mandatory = $false,Position = 2)]
    [System.IO.FileInfo]$OutputFile,

    [Parameter(ParameterSetName = "RemoteSigning",Mandatory = $true,Position = 3)]
    [string]$RemoteEndorsementKeyID,

    [Parameter(ParameterSetName = "RemoteSigning",Mandatory = $true,Position = 4)]
    [string]$RemoteSigningServiceURL,

    [Parameter(ParameterSetName = "RemoteSigning",Mandatory = $false,Position = 5)]
    [switch]$CacheAccessToken
  )

  # only allow https or file paths with or without file:// URL prefix
  if ($RemoteSigningServiceURL -and -not ($RemoteSigningServiceURL.StartsWith("https://",$true,$null) -or [System.IO.Directory]::Exists($RemoteSigningServiceURL) -or $RemoteSigningServiceURL.StartsWith("file://",$true,$null))) {
    throw [System.ArgumentException]"Only HTTPS or valid existing directory paths are supported."
  }

  New-HPSecurePlatformSigningKeyProvisioningPayload @PSBoundParameters
}

<#
.SYNOPSIS
  Applies a payload to HP Secure Platform Management

.DESCRIPTION
  This command applies a properly encoded payload created by one of the New-HPSecurePlatform*, New-HPSureRun*, New-HPSureAdmin*, or New-HPSureRecover* commands to the BIOS.
  
  Payloads created by means other than the commands mentioned above are not supported.

  Security note: Payloads should only be created on secure servers. Once created, the payload may be transferred to a client and applied via the Set-HPSecurePlatformPayload command. Creating the payload and passing it to the Set-HPSecurePlatformPayload command via the pipeline is not a recommended production pattern.

.PARAMETER Payload
  Specifies the payload to apply. This parameter can also be specified via the pipeline.

.PARAMETER PayloadFile
  Specifies the payload file to apply. This file must contain a properly encoded payload.

.LINK
  [Blog post: HP Secure Platform Management with the HP Client Management Script Library](https://developers.hp.com/hp-client-management/blog/hp-secure-platform-management-hp-client-management-script-library)

.NOTES
  - Requires HP BIOS with Secure Platform Management support.
  - This command requires elevated privileges.

.EXAMPLE
  Set-HPSecurePlatformPayload -Payload $payload

.EXAMPLE
  Set-HPSecurePlatformPayload -PayloadFile .\payload.dat

.EXAMPLE
  $payload | Set-HPSecurePlatformPayload
#>
function Set-HPSecurePlatformPayload {

  [CmdletBinding(DefaultParameterSetName = "FB",HelpUri = "https://developers.hp.com/hp-client-management/doc/Set-HPSecurePlatformPayload")]
  param(
    [Parameter(ParameterSetName = "FB",ValueFromPipeline = $true,Position = 0,Mandatory = $True)] [string]$Payload,
    [Parameter(ParameterSetName = "FF",ValueFromPipeline = $true,Position = 0,Mandatory = $True)] [System.IO.FileInfo]$PayloadFile
  )

  if ($PSCmdlet.ParameterSetName -eq "FB") {
    Write-Verbose "Setting payload string"
    [PortableFileFormat]$type = ConvertFrom-Json -InputObject $Payload
  }
  else {
    Write-Verbose "Setting from file $PayloadFile"
    $Payload = Get-Content -Path $PayloadFile -Encoding UTF8
    [PortableFileFormat]$type = ConvertFrom-Json -InputObject $Payload
  }

  $mi_result = 0
  $pbytes = $type.Data
  Write-Verbose "Setting payload from document with type $($type.purpose)"

  $cmd = $null
  switch ($type.purpose) {
    "hp:provision:endorsementkey" {
      $cmd = '[DfmNativeSecurePlatform]::set_ek_provisioning' + (Test-OSBitness) + '($pbytes,$pbytes.length, [ref]$mi_result);'
    }
    "hp:provision:signingkey" {
      $cmd = '[DfmNativeSecurePlatform]::set_sk_provisioning' + (Test-OSBitness) + '($pbytes,$pbytes.length, [ref]$mi_result);'
    }
    "hp:surerecover:provision:os_image" {
      $cmd = '[DfmNativeSureRecover]::set_surerecover_osr_provisioning' + (Test-OSBitness) + '($pbytes,$pbytes.length, [ref]$mi_result);'
    }
    "hp:surerecover:provision:recovery_image" {
      $cmd = '[DfmNativeSureRecover]::set_surerecover_re_provisioning' + (Test-OSBitness) + '($pbytes,$pbytes.length, [ref]$mi_result);'
    }
    "hp:surerecover:failover:os_image" {
      if (-not (Get-HPSureRecoverState).ImageIsProvisioned) {
        throw [System.IO.InvalidDataException]"Custom OS Recovery Image is required to configure failover"
      }
      $cmd = '[DfmNativeSureRecover]::set_surerecover_osr_failover' + (Test-OSBitness) + '($pbytes,$pbytes.length,[ref]$mi_result);'
    }
    "hp:surerecover:deprovision" {
      $cmd = '[DfmNativeSureRecover]::set_surerecover_deprovision_opaque' + (Test-OSBitness) + '($pbytes,$pbytes.length, [ref]$mi_result);'
    }
    "hp:surerecover:scheduler" {
      $cmd = '[DfmNativeSureRecover]::set_surerecover_schedule' + (Test-OSBitness) + '($pbytes,$pbytes.length, [ref]$mi_result);'
    }
    "hp:surerecover:configure" {
      $cmd = '[DfmNativeSureRecover]::set_surerecover_configuration' + (Test-OSBitness) + '($pbytes,$pbytes.length, [ref]$mi_result);'
    }
    "hp:surerecover:trigger" {
      $cmd = '[DfmNativeSureRecover]::set_surerecover_trigger' + (Test-OSBitness) + '($pbytes,$pbytes.length, [ref]$mi_result);'
    }
    "hp:surerecover:service_event" {
      $cmd = '[DfmNativeSureRecover]::raise_surerecover_service_event_opaque' + (Test-OSBitness) + '($null,0, [ref]$mi_result);'
    }
    "hp:surerrun:manifest" {
      $mbytes = $type.Meta1
      $cmd = '[DfmNativeSureRun]::set_surererun_manifest' + (Test-OSBitness) + '($pbytes,$pbytes.length, $mbytes, $mbytes.length, [ref]$mi_result);'
    }
    "hp:sureadmin:biossetting" {
      $Payload | Set-HPPrivateBIOSSettingValuePayload -Verbose:$VerbosePreference
    }
    "hp:sureadmin:biossettingslist" {
      $Payload | Set-HPPrivateBIOSSettingsListPayload -Verbose:$VerbosePreference
    }
    "hp:sureadmin:resetsettings" {
      $Payload | Set-HPPrivateBIOSSettingDefaultsPayload -Verbose:$VerbosePreference
    }
    "hp:sureadmin:firmwareupdate" {
      $Payload | Set-HPPrivateFirmwareUpdatePayload -Verbose:$VerbosePreference
    }
    default {
      throw [System.IO.InvalidDataException]"Document type $($type.purpose) not recognized"
    }
  }
  if ($cmd) {
    $result = Invoke-Expression -Command $cmd
    Test-HPPrivateCustomResult -result $result -mi_result $mi_result -Category 0x04
  }
}

# SIG # Begin signature block
# MIIoHQYJKoZIhvcNAQcCoIIoDjCCKAoCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCPbIvJ1ezLEazw
# 2MI9WlZy4UZerqvkOdTzi6B/+NNY7qCCDYowggawMIIEmKADAgECAhAIrUCyYNKc
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
# KwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBm7d9Bf
# +H//DL9QLWKIA/nNHnXDFjhUiXvI0Y9OO/O9MA0GCSqGSIb3DQEBAQUABIIBgGHA
# aVJRhqwRb8xLw1ELPwsk6fHFadqq3jpojeN8hh+6V/XDKAgdks83ytQWFR5QLGMJ
# RjbFwjRAPkZeWsSg6Lza2YP++xJKz29JxV1BUEl9s/k5CEgQy2fjg24qb34jky3v
# nTw17hcXsoK7xUE+KdKn3bg1qq3iUAFkyc0Di1ueB5R5YuHrxK/UA039ydZGmguL
# zt8BQSYwJXsdoahKvuttndKEMwlTygasN+/T5QG8Y42bHIWWYsoOkzs1mNv10xVh
# 6BeC0vPisLrjeo0krXVDe5DXare7usnUJDEPCAFNrjEQdTz5ucBZmp0eWBAHhT0+
# Dsp5ZMmDDKohSUNYy+MA7352EzBibsOXmDuFin09GMSjghhluvkatfHFCDy2lM5e
# 6iqhG/cNp1bBIjHoEKMlVsqzZltqhJe0ExqgrmneaABctC1wmTH77Iw2W+yaWwHr
# XNG5oCFKadOloPtZYYx5xqWVf6WVCL+ES3bPrgkdinRSuxoadmM2l64+WGt5zqGC
# Fz8wghc7BgorBgEEAYI3AwMBMYIXKzCCFycGCSqGSIb3DQEHAqCCFxgwghcUAgED
# MQ8wDQYJYIZIAWUDBAIBBQAwdwYLKoZIhvcNAQkQAQSgaARmMGQCAQEGCWCGSAGG
# /WwHATAxMA0GCWCGSAFlAwQCAQUABCAWQhhKqn1tm48MIetsdzrt9P9o14vnNI3/
# KdXBvJYGFwIQaJ4xMeRLdtZGxWS5M1CIPhgPMjAyNDA4MjcxNjU1NTBaoIITCTCC
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
# BDEiBCCr/nTqH8mGV8bM/sng2USxomZUmjy/kw3C/6eeqEJBgzA3BgsqhkiG9w0B
# CRACLzEoMCYwJDAiBCDS9uRt7XQizNHUQFdoQTZvgoraVZquMxavTRqa1Ax4KDAN
# BgkqhkiG9w0BAQEFAASCAgCiaV+bkgE+ZNiVK4StBHYcRTR8x+kLJdtEd6nGjH0s
# NE+sdEBYxU9n2O2h+I3bdqVb/1jxNlB6ckLDKspg5QSDrhWEpM032ZxuVvNpj4Zv
# PBuu1esY8vNlMUVdHKzKoKnpyU7SD49oT6VPqXd0svIUfCIiz5+NwMyJySKmsKHx
# g5JmoHdp5NM7xnqVfpuYIsztOlnxSDJiudBpksZ931iORJXTMMkhXHwhV4eN0ipG
# 2v6v9oXK0mD3+++7CCGhN0uZe8Tjqzd0LBZP2ZE08vda9u3vXpcu4e5Tu4qdS70c
# YBt2FnGeiAgcU9UuzwWIWdtUzmQf4LNHwS8zDBC8VYTyLMqivYDIxHvcAutvsC/L
# kcrWiK5XieA/E/bP5Qn3knqrwyLJq6fGF+ZZo9hqE+mR0bd/9WTaLF7hTc7wpV62
# jYDwlKOaK1aDMtxiC2c9+ODGKMZVXzms/nO4Lpw+CwIIQ1z54TGdrW3gP0jRtJr4
# QGUKnb6nToNVawo8GermSuMA0c90DtS0op1UJNKZIBJa12QrAztaa6BMRfW0UjmS
# xCriQykP1lsCvk9Mx340GudzevoT9G8z9on5qma83I0B2GGY8S7rv5f+UGMKpApD
# 4GdEHuqLdhORShSNEEE2KQEMIuXRADQbXjTou0mtyHhvgIaXT//8ujkPzbfUtgxl
# nw==
# SIG # End signature block
