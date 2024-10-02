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
#requires -Modules "HP.Private","HP.Softpaq","HP.Sinks"

# CMSL is normally installed in C:\Program Files\WindowsPowerShell\Modules
# but if installed via PSGallery and via PS7, it is installed in a different location
if (Test-Path "$PSScriptRoot\..\HP.Private\HP.CMSLHelper.dll") {
  Add-Type -Path "$PSScriptRoot\..\HP.Private\HP.CMSLHelper.dll"
}
else{
  Add-Type -Path "$PSScriptRoot\..\..\HP.Private\1.7.2\HP.CMSLHelper.dll"
}

enum ErrorHandling
{
  Fail = 0
  LogAndContinue = 1
}

$REPOFILE = ".repository/repository.json"
$LOGFILE = ".repository/activity.log"

# print a bare error
function err
{
  [CmdletBinding()]
  param(
    [string]$str,
    [boolean]$withLog = $true
  )

  [console]::ForegroundColor = 'red'
  [console]::Error.WriteLine($str)
  [console]::ResetColor()

  if ($withLog) { Write-LogError -Message $str -Component "HP.Repo" -File $LOGFILE }
}

# convert a date object to an 8601 string
function ISO8601DateString
{
  [CmdletBinding()]
  param(
    [datetime]$Date
  )
  $Date.ToString("yyyy-MM-dd'T'HH:mm:ss.fffffff",[System.Globalization.CultureInfo]::InvariantCulture)
}

# get current user name
function GetUserName ()
{
  [CmdletBinding()]
  param()

  try {
    [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
  }
  catch {
    return $env:username
  }
}

# check if a file exists
function FileExists
{
  [CmdletBinding()]
  param(
    [string]$File
  )
  Test-Path $File -PathType Leaf
}

# load a json object
function LoadJson
{
  [CmdletBinding()]
  param(
    [string]$File
  )

  try {
    $PS7Mark = "PS7Mark"
    $rawData = (Get-Content -Raw -Path $File) -replace '("DateLastModified": ")([^"]+)(")',('$1' + $PS7Mark + '$2' + $PS7Mark + '$3')
    [SoftpaqRepositoryFile]$result = $rawData | ConvertFrom-Json
    $result.DateLastModified = $result.DateLastModified -replace $PS7Mark,""
    return $result
  }
  catch
  {
    err ("Could not parse '$File'  $($_.Exception.Message)")
    return $Null
  }
}

# load a repository definition file
function LoadRepository
{
  [CmdletBinding()]
  param()

  Write-Verbose "loading $REPOFILE"
  $inRepo = FileExists -File $REPOFILE
  if (-not $inRepo) {
    throw [System.Management.Automation.ItemNotFoundException]"Directory '$(Get-Location)' is not a repository."
  }

  $repo = LoadJson -File $REPOFILE
  if (-not $repo -eq $null)
  {
    err ("Could not initialize the repository: $($_.Exception.Message)")
    return $false,$null
  }

  if (-not $repo.Filters) { $repo.Filters = @() }

  if (-not $repo.settings) {
    $repo.settings = New-Object SoftpaqRepositoryFile+Configuration
  }

  if (-not $repo.settings.OnRemoteFileNotFound) {
    $repo.settings.OnRemoteFileNotFound = [ErrorHandling]::Fail
  }

  if (-not $repo.settings.ExclusiveLockMaxRetries) {
    $repo.settings.ExclusiveLockMaxRetries = 10
  }

  if (-not $repo.settings.OfflineCacheMode) {
    $repo.settings.OfflineCacheMode = "Disable"
  }

  if (-not $repo.settings.RepositoryReport) {
    $repo.settings.RepositoryReport = "CSV"
  }

  foreach ($filter in $repo.Filters)
  {
    if (-not $filter.characteristic)
    {
      $filter.characteristic = "*"
    }
    if (-not $filter.preferLTSC)
    {
      $filter.preferLTSC = $false
    }
  }

  if (-not $repo.Notifications) {
    $repo.Notifications = New-Object SoftpaqRepositoryFile+NotificationConfiguration
    $repo.Notifications.port = 25
    $repo.Notifications.tls = $false
    $repo.Notifications.UserName = ""
    $repo.Notifications.Password = ""
    $repo.Notifications.from = "softpaq-repo-sync@$($env:userdnsdomain)"
    $repo.Notifications.fromname = "Softpaq Repository Notification"
  }

  Write-Verbose "load success"
  return $true,$repo
}

# This function downloads SoftPaq CVA, if SoftPaq exe already exists, checks signature of SoftPaq exe. If redownload required, SoftPaq exe will be downloaded. 
# Note that CVAs are always downloaded since there is no reliable way to check their consistency.
function DownloadSoftpaq
{
  [CmdletBinding()]
  param(
    $DownloadSoftpaqCmd,
    [int]$MaxRetries = 10
  )

  $download_file = $true
  $EXEname = "sp" + $DownloadSoftpaqCmd.number + ".exe"
  $CVAname = "sp" + $DownloadSoftpaqCmd.number + ".cva"

  # download the SoftPaq CVA. Existing CVAs are always overwritten.
  Write-Verbose ("Downloading CVA $($DownloadSoftpaqCmd.number)")
  Log ("    sp$($DownloadSoftpaqCmd.number).cva - Downloading CVA file.")
  Get-SoftpaqMetadataFile @DownloadSoftpaqCmd -MaxRetries $MaxRetries -Overwrite "Yes"
  Log ("    sp$($DownloadSoftpaqCmd.number).cva - Done downloading CVA file.")

  # check if the SoftPaq exe already exists
  if (FileExists -File $EXEname) {
    Write-Verbose "Checking signature for existing file $EXEname"
    if (Get-HPPrivateCheckSignature -File $EXEname -CVAfile $CVAname -Verbose:$VerbosePreference -Progress:(-not $DownloadSoftpaqCmd.Quiet)) {

      # existing SoftPaq exe passes signature check. No need to redownload
      $download_file = $false

      if (-not $DownloadSoftpaqCmd.Quiet) {
        Write-Host -ForegroundColor Magenta "File $EXEname already exists and passes signature check. It will not be redownloaded."
      }

      Log ("    sp$($DownloadSoftpaqCmd.number).exe - Already exists. Will not redownload.")
    }
    else {
      # existing SoftPaq exe failed signature check. Need to delete it and redownload
      Write-Verbose ("Need to redownload file '$EXEname'")
    }
  }
  else {
    Write-Verbose ("Need to download file '$EXEname'")
  }

  # download the SoftPaq exe if needed
  if ($download_file -eq $true) {
    try {
      Log ("    sp$($DownloadSoftpaqCmd.number).exe - Downloading EXE file.")
      
      # download the SoftPaq exe
      Get-Softpaq @DownloadSoftpaqCmd -MaxRetries $MaxRetries -Overwrite yes

      # check newly downloaded SoftPaq exe signature
      if (-not (Get-HPPrivateCheckSignature -File $EXEname -CVAfile $CVAname -Verbose:$VerbosePreference -Progress:(-not $DownloadSoftpaqCmd.Quiet))) {

        # delete SoftPaq CVA and EXE since the EXE failed signature check
        Remove-Item -Path $EXEname -Force -Verbose:$VerbosePreference
        Remove-Item -Path $CVAName -Force -Verbose:$VerbosePreference

        $msg = "File $EXEname failed integrity check and has been deleted, will retry download next sync"
        if (-not $DownloadSoftpaqCmd.Quiet) {
          Write-Host -ForegroundColor Magenta $msg
        }
        Write-LogWarning -Message $msg -Component "HP.Repo" -File $LOGFILE
      }
      else {
        Log ("    sp$($DownloadSoftpaqCmd.number).exe - Done downloading EXE file.")
      }
    }
    catch {
      Write-Host -ForegroundColor Magenta "File sp$($DownloadSoftpaqCmd.number).exe has invalid or missing signature and will be deleted."
      Log ("    sp$($DownloadSoftpaqCmd.number).exe has invalid or missing signature and will be deleted.")
      Log ("    sp$($DownloadSoftpaqCmd.number).exe - Redownloading EXE file.")
      Get-Softpaq @DownloadSoftpaqCmd -maxRetries $maxRetries
      Log ("    sp$($DownloadSoftpaqCmd.number).exe - Done downloading EXE file.")
    }
  }
}

# write a repository definition file
function WriteRepositoryFile
{
  [CmdletBinding()]
  param($obj)

  $now = Get-Date
  $obj.DateLastModified = ISO8601DateString -Date $now
  $obj.ModifiedBy = GetUserName
  Write-Verbose "Writing repository file to $REPOFILE"
  $obj | ConvertTo-Json | Out-File -Force $REPOFILE
}

# check if a filter exists in a repo object
function FilterExists
{
  [CmdletBinding()]
  param($repo,$f)

  $c = getFilters $repo $f
  return ($null -ne $c)
}

# get a list of filters in a repo, matching exact parameters
function getFilters
{
  [CmdletBinding()]
  param($repo,$f)

  if ($repo.Filters.Count -eq 0) { return $null }
  $repo.Filters | Where-Object {
    $_.platform -eq $f.platform -and
    $_.OperatingSystem -eq $f.OperatingSystem -and
    $_.Category -eq $f.Category -and
    $_.ReleaseType -eq $f.ReleaseType -and
    $_.characteristic -eq $f.characteristic -and
    $_.preferLTSC -eq $f.preferLTSC
  }
}

# get a list of filters in a repo, considering empty parameters as wildcards
function GetFiltersWild
{
  [CmdletBinding()]
  param($repo,$f)

  if ($repo.Filters.Count -eq 0) { return $null }
  $repo.Filters | Where-Object {
    $_.platform -eq $f.platform -and
    (
      $_.OperatingSystem -eq $f.OperatingSystem -or
      $f.OperatingSystem -eq "*" -or
      ($f.OperatingSystem -eq "win10:*" -and $_.OperatingSystem.StartsWith("win10")) -or
      ($f.OperatingSystem -eq "win11:*" -and $_.OperatingSystem.StartsWith("win11"))
    ) -and
    ($_.Category -eq $f.Category -or $f.Category -eq "*") -and
    ($_.ReleaseType -eq $f.ReleaseType -or $f.ReleaseType -eq "*") -and
    ($_.characteristic -eq $f.characteristic -or $f.characteristic -eq "*") -and
    ($_.preferLTSC -eq $f.preferLTSC -or $null -eq $f.preferLTSC)
  }
}

# write a log entry to the .repository/activity.log
function Log
{
  [CmdletBinding()]
  param([string[]]$entryText)

  foreach ($line in $entryText)
  {
    if (-not $line) {
      $line = " "
    }
    Write-LogInfo -Message $line -Component "HP.Repo" -File $LOGFILE
  }

}

# touch a file (change its date if exists, or create it if it doesn't.
function TouchFile
{
  [CmdletBinding()]
  param([string]$File)

  if (Test-Path $File) { (Get-ChildItem $File).LastWriteTime = Get-Date }
  else { Write-Output $null > $File }
}


# remove all marks from the repository
function FlushMarks
{
  [CmdletBinding()]
  param()

  Write-Verbose "Removing all marks"
  Remove-Item ".repository\mark\*" -Include "*.mark"
}


# send a notification email
function Send
{
  [CmdletBinding()]
  param(
    $subject,
    $body,
    $html = $true
  )

  $n = Get-RepositoryNotificationConfiguration
  if ((-not $n) -or (-not $n.server)) {
    Write-Verbose ("Notifications are not configured")
    return
  }

  try {
    if ((-not $n.addresses) -or (-not $n.addresses.Count))
    {
      Write-Verbose ("Notifications have no recipients defined")
      return
    }
    Log ("Sending a notification email")

    $params = @{}
    $params.To = $n.addresses
    $params.SmtpServer = $n.server
    $params.port = $n.port
    $params.UseSsl = $n.tls
    $params.from = "$($n.fromname) <$($n.from)>"
    $params.Subject = $subject
    $params.Body = $body
    $params.BodyAsHtml = $html

    Write-Verbose ("server: $($params.SmtpServer)")
    Write-Verbose ("port: $($params.Port)")

    if ([string]::IsNullOrEmpty($n.UserName) -eq $false)
    {
      try {
        [SecureString]$read = $n.Password | ConvertTo-SecureString
        $params.Credential = New-Object System.Management.Automation.PSCredential ($n.UserName,$read)
        if (-not $params.Credential) {
          Log ("Could not build credential object from username and password")
          return;
        }
      }
      catch {
        err ("Failed to build credential object from username and password: $($_.Exception.Message)")
        return
      }
    }
    Send-MailMessage @params -ErrorAction Stop
  }
  catch {
    err ("Could not send email: $($_.Exception.Message)")
    return
  }
  Write-Verbose ("Send complete.")
}

<#
.SYNOPSIS
    Initializes a repository in the current directory

.DESCRIPTION
  This command initializes a directory to be used as a repository. This command creates a .repository folder in the current directory,
  which contains the definition of the .repository and all its settings.

  In order to un-initalize a directory, simple remove the .repository folder.

  After initializing a repository, you must add at least one filter to define the content that this repository will receive.

  If the directory already contains a repository, this command will fail.

.EXAMPLE
    Initialize-Repository

.LINK
  [Add-RepositoryFilter](https://developers.hp.com/hp-client-management/doc/Add-RepositoryFilter)

.LINK
  [Remove-RepositoryFilter](https://developers.hp.com/hp-client-management/doc/Remove-RepositoryFilter)

.LINK
  [Get-RepositoryInfo](https://developers.hp.com/hp-client-management/doc/Get-RepositoryInfo)

.LINK
  [Invoke-RepositorySync](https://developers.hp.com/hp-client-management/doc/Invoke-RepositorySync)

.LINK
  [Invoke-RepositoryCleanup](https://developers.hp.com/hp-client-management/doc/Invoke-RepositoryCleanup)

.LINK
  [Set-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Set-RepositoryNotificationConfiguration)

.LINK
  [Clear-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Clear-RepositoryNotificationConfiguration)

.LINK 
  [Get-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Get-RepositoryNotificationConfiguration)

.LINK 
  [Show-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Show-RepositoryNotificationConfiguration)

.LINK
  [Add-RepositorySyncFailureRecipient](https://developers.hp.com/hp-client-management/doc/Add-RepositorySyncFailureRecipient)

.LINK
  [Remove-RepositorySyncFailureRecipient](https://developers.hp.com/hp-client-management/doc/Remove-RepositorySyncFailureRecipient)

.LINK
  [Test-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Test-RepositoryNotificationConfiguration)

.LINK
  [Get-RepositoryConfiguration](https://developers.hp.com/hp-client-management/doc/Get-RepositoryConfiguration)

.LINK
  [Set-RepositoryConfiguration](https://developers.hp.com/hp-client-management/doc/Set-RepositoryConfiguration)
#>
function Initialize-Repository
{
  [CmdletBinding(HelpUri = "https://developers.hp.com/hp-client-management/doc/Initialize-Repository")]
  param()

  if (FileExists -File $REPOFILE) {
    err "This directory is already initialized as a repository."
    return
  }
  $now = Get-Date
  $newRepositoryFile = New-Object SoftpaqRepositoryFile

  $newRepositoryFile.settings = New-Object SoftpaqRepositoryFile+Configuration
  $newRepositoryFile.settings.OnRemoteFileNotFound = [ErrorHandling]::Fail
  $newRepositoryFile.settings.ExclusiveLockMaxRetries = 10
  $newRepositoryFile.settings.OfflineCacheMode = "Disable"
  $newRepositoryFile.settings.RepositoryReport = "CSV"

  $newRepositoryFile.DateCreated = ISO8601DateString -Date $now
  $newRepositoryFile.CreatedBy = GetUserName

  try {
    New-Item -ItemType directory -Path .repository | Out-Null
    WriteRepositoryFile -obj $newRepositoryFile
    New-Item -ItemType directory -Path ".repository/mark" | Out-Null
  }
  catch {
    err ("Could not initialize the repository: $($_.Exception.Message)")
    return
  }
  Log "Repository initialized successfully."
}

<#
.SYNOPSIS
  Adds a filter per specified platform to the current repository

.DESCRIPTION
  This command adds a filter to a repository that was previously initialized by the Initialize-Repository command. A repository can contain one or more filters, and filtering will be the based on all the filters defined. Please note that "*" means "current" for the -Os parameter but means "all" for the -Category, -ReleaseType, -Characteristic parameters. 

  .PARAMETER Platform
  Specifies the platform using its platform ID to include in this repository. A platform ID, a 4-digit hexadecimal number, can be obtained by executing the Get-HPDeviceProductID command. This parameter is mandatory. 

.PARAMETER Os
  Specifies the operating system to be included in this repository. The value must be one of 'win10' or 'win11'. If not specified, the current operating system will be assumed, which may not be what is intended.

.PARAMETER OsVer
  Specifies the target OS Version (e.g. '1809', '1903', '1909', '2004', '2009', '21H1', '21H2', '22H2', '23H2', '24H2', etc). Starting from the '21H1' release, 'xxHx' format is expected. If not specified, the current operating system version will be assumed, which may not be what is intended.

.PARAMETER Category
  Specifies the SoftPaq category to be included in this repository. The value must be one (or more) of the following values: 
  - Bios
  - Firmware
  - Driver
  - Software
  - OS
  - Manageability
  - Diagnostic
  - Utility
  - Driverpack
  - Dock
  - UWPPack

  If not specified, all categories will be included.

.PARAMETER ReleaseType
  Specifies a release type for this command to filter based on. The value must be one (or more) of the following values:
  - Critical
  - Recommended
  - Routine

  If not specified, all release types are included.

.PARAMETER Characteristic
  Specifies the characteristic to be included in this repository. The value must be one of the following values:
  - SSM
  - DPB
  - UWP
  
  If this parameter is not specified, all characteristics are included.

.PARAMETER PreferLTSC
  If specified and if the data file exists, this command uses the Long-Term Servicing Branch/Long-Term Servicing Channel (LTSB/LTSC) Reference file for the specified platform ID. If the data file does not exist, this command uses the regular Reference file for the specified platform.

.EXAMPLE
  Add-RepositoryFilter -Platform 1234 -Os win10 -OsVer 2009

.EXAMPLE
  Add-RepositoryFilter -Platform 1234 -Os win10 -OsVer "21H1"

.EXAMPLE
  Add-RepositoryFilter -Platform 1234 -Os win10 -OsVer "21H1" -PreferLTSC

.LINK
  [Initialize-Repository](https://developers.hp.com/hp-client-management/doc/Initialize-Repository)

.LINK
  [Remove-RepositoryFilter](https://developers.hp.com/hp-client-management/doc/Remove-RepositoryFilter)

.LINK
  [Get-RepositoryInfo](https://developers.hp.com/hp-client-management/doc/Get-RepositoryInfo)

.LINK
  [Invoke-RepositoryCleanup](https://developers.hp.com/hp-client-management/doc/Invoke-RepositoryCleanup)

.LINK
  [Invoke-RepositorySync](https://developers.hp.com/hp-client-management/doc/Invoke-RepositorySync)

.LINK
  [Set-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Set-RepositoryNotificationConfiguration)

.LINK
  [Clear-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Clear-RepositoryNotificationConfiguration)

.LINK 
  [Get-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Get-RepositoryNotificationConfiguration)

.LINK 
  [Show-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Show-RepositoryNotificationConfiguration)

.LINK
  [Add-RepositorySyncFailureRecipient](https://developers.hp.com/hp-client-management/doc/Add-RepositorySyncFailureRecipient)

.LINK
  [Remove-RepositorySyncFailureRecipient](https://developers.hp.com/hp-client-management/doc/Remove-RepositorySyncFailureRecipient)

.LINK
  [Test-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Test-RepositoryNotificationConfiguration)

.LINK
  [Get-HPDeviceProductID](https://developers.hp.com/hp-client-management/doc/Get-HPDeviceProductID)
#>
function Add-RepositoryFilter
{
  [CmdletBinding(HelpUri = "https://developers.hp.com/hp-client-management/doc/Add-RepositoryFilter")]
  param(
    [ValidatePattern("^[a-fA-F0-9]{4}$")]
    [Parameter(Position = 0,Mandatory = $true)]
    [string]$Platform,

    [ValidateSet("win7","win8","win8.1","win81","win10","win11","*")] # keep in sync with the SoftPaq module
    [Parameter(Position = 1)] $Os = "*", # counterintuitively, "*" for this Os parameter means "current"  
    [string[]]

    [ValidateSet("1809","1903","1909","2004","2009","21H1","21H2","22H2", "23H2", "24H2")] # keep in sync with the SoftPaq module
    [Parameter(Position = 1)]
    [string]$OsVer,

    [ValidateSet("Bios","Firmware","Driver","Software","Os","Manageability","Diagnostic","Utility","Driverpack","Dock","UWPPack","*")] # keep in sync with the SoftPaq module
    [Parameter(Position = 2)]
    [string[]]$Category = "*",

    [ValidateSet("Critical","Recommended","Routine","*")] # keep in sync with the SoftPaq module
    [Parameter(Position = 3)]
    [string[]]$ReleaseType = "*",

    [ValidateSet("SSM","DPB","UWP","*")] # keep in sync with the SoftPaq module
    [Parameter(Position = 4)]
    [string[]]$Characteristic = "*",

    [Parameter(Position = 5, Mandatory = $false)]
    [switch]$PreferLTSC
  )

  $c = LoadRepository
  try {
    if ($c[0] -eq $false) { return }
    $repo = $c[1]

    $newFilter = New-Object SoftpaqRepositoryFile+SoftpaqRepositoryFilter
    $newFilter.platform = $Platform

    $newFilter.OperatingSystem = $Os
    if (-not $OsVer)
    {
      $OsVer = GetCurrentOSVer
    }
    if ($OsVer) { $OsVer = $OsVer.ToLower() }
    if ($Os -eq "win10") { $newFilter.OperatingSystem = "win10:$OsVer" }
    elseif ($Os -eq "win11") { $newFilter.OperatingSystem = "win11:$OsVer" }

    $newFilter.Category = $Category
    $newFilter.ReleaseType = $ReleaseType
    $newFilter.characteristic = $Characteristic
    $newFilter.preferLTSC = $PreferLTSC.IsPresent

    # silently ignore if the filter is already in the repo
    $exists = filterExists $repo $newFilter
    if (!$exists) {
      $repo.Filters += $newFilter
      WriteRepositoryFile -obj $repo
      if ($OsVer -and $Os -ne '*') { Log "Added filter $Platform {{ os='$Os', osver='$OsVer', category='$Category', release='$ReleaseType', characteristic='$Characteristic', preferLTSC='$($PreferLTSC.IsPresent)' }}" }
      else { Log "Added filter $Platform {{ os='$Os', category='$Category', release='$ReleaseType', characteristic='$Characteristic', preferLTSC='$($PreferLTSC.IsPresent)' }}" }
    }
    else
    {
      Write-Verbose "Silently ignoring this filter since exact match is already in the repository"
    }
    Write-Verbose "Repository filter added."
  }
  catch
  {
    err ("Could not add filter to the repository:  $($_.Exception.Message)")
  }
}


<#
.SYNOPSIS
  Removes one or more previously added filters per specified platform from the current repository

.DESCRIPTION
  This command removes one or more previously added filters per specified platform from the current repository. Please note that "*" means "current" for the -Os parameter but means "all" for the -Category, -ReleaseType, -Characteristic parameters.

.PARAMETER Platform
  Specifies the platform to be removed from this repository. This is a 4-digit hex number that can be obtained via the Get-HPDeviceProductID command. This parameter is mandatory. 

.PARAMETER Os
 Specifies an OS for this command to be removed from this repository. The value must be 'win10' or 'win11'. If not specified, the current operating system will be assumed, which may not be what is intended.

.PARAMETER OsVer
  Specifies the target OS Version (e.g. '1809', '1903', '1909', '2004', '2009', '21H1', '21H2', '22H2', '23H2', '24H2', etc). Starting from the '21H1' release, 'xxHx' format is expected. If the parameter is not specified, the current operating system version will be assumed, which may not be what is intended.

.PARAMETER Category
  Specifies the SoftPaq category to be removed from this repository. The value must be one (or more) of the following values: 
  - Bios
  - Firmware
  - Driver
  - Software
  - OS
  - Manageability
  - Diagnostic
  - Utility
  - Driverpack
  - Dock
  - UWPPack

  If not specified, all categories will be removed.

.PARAMETER ReleaseType
  Specifies the release type for this command to remove from this repository. If not specified, all release types will be removed. The value must be one (or more) of the following values:
  - Critical
  - Recommended
  - Routine
  
  If this parameter is not specified, all release types will be removed. 

.PARAMETER Characteristic
  Specifies the characteristic to be removed from this repository. The value must be one of the following values:
  - SSM
  - DPB
  - UWP
  
  If this parameter is not specified, all characteristics are included. If not specified, all characteristics will be removed.

.PARAMETER PreferLTSC
  If specified, this command uses the Long-Term Servicing Branch/Long-Term Servicing Channel (LTSB/LTSC) Reference file for the specified platform. If not specified, all preferences will be matched.

.PARAMETER Yes
  If specified, this command will delete the filter without asking for confirmation. If not specified, this command will ask for confirmation before deleting a filter. 

.EXAMPLE
  Remove-RepositoryFilter -Platform 1234

.EXAMPLE
  Remove-RepositoryFilter -Platform 1234 -Os win10 -OsVer "21H1"

.EXAMPLE
  Remove-RepositoryFilter -Platform 1234 -Os win10 -OsVer "21H1" -PreferLTSC $True

.LINK
  [Initialize-Repository](https://developers.hp.com/hp-client-management/doc/Initialize-Repository)

.LINK
  [Add-RepositoryFilter](https://developers.hp.com/hp-client-management/doc/Add-RepositoryFilter)

.LINK
  [Get-RepositoryInfo](https://developers.hp.com/hp-client-management/doc/Get-RepositoryInfo)

.LINK
  [Invoke-RepositoryCleanup](https://developers.hp.com/hp-client-management/doc/Invoke-RepositoryCleanup)

.LINK
  [Invoke-RepositorySync](https://developers.hp.com/hp-client-management/doc/Invoke-RepositorySync)

.LINK
  [Set-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Set-RepositoryNotificationConfiguration)

.LINK
  [Clear-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Clear-RepositoryNotificationConfiguration)

.LINK 
  [Get-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Get-RepositoryNotificationConfiguration)

.LINK 
  [Show-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Show-RepositoryNotificationConfiguration)

.LINK
  [Add-RepositorySyncFailureRecipient](https://developers.hp.com/hp-client-management/doc/Add-RepositorySyncFailureRecipient)

.LINK
  [Remove-RepositorySyncFailureRecipient](https://developers.hp.com/hp-client-management/doc/Remove-RepositorySyncFailureRecipient)

.LINK
  [Get-HPDeviceProductID](https://developers.hp.com/hp-client-management/doc/Get-HPDeviceProductID)

.LINK
  [Test-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Test-RepositoryNotificationConfiguration)
#>
function Remove-RepositoryFilter
{
  [CmdletBinding(HelpUri = "https://developers.hp.com/hp-client-management/doc/Remove-RepositoryFilter")]
  param(
    [ValidatePattern("^[a-fA-F0-9]{4}$")]
    [Parameter(Position = 0,Mandatory = $true)]
    [string]$Platform,

    [ValidateSet("win7","win8","win8.1","win81","win10","win11","*")] # keep in sync with the SoftPaq module
    [string[]]
    [Parameter(Position = 1)]
    $Os = "*", # counterintuitively, "*" for this Os parameter means "current"

    [ValidateSet("1809","1903","1909","2004","2009","21H1","21H2","22H2", "23H2", "24H2")] # keep in sync with the SoftPaq module
    [Parameter(Position = 1)]
    [string]$OsVer,

    [ValidateSet("Bios","Firmware","Driver","Software","Os","Manageability","Diagnostic","Utility","Driverpack","Dock","UWPPack","*")] # keep in sync with the SoftPaq module
    [string[]]
    [Parameter(Position = 2)]
    $Category = "*",

    [ValidateSet("Critical","Recommended","Routine","*")] # keep in sync with the SoftPaq module
    [string[]]
    [Parameter(Position = 3)]
    $ReleaseType = "*",

    [Parameter(Position = 4,Mandatory = $false)]
    [switch]$Yes = $false,

    [ValidateSet("SSM","DPB","UWP","*")] # keep in sync with the SoftPaq module
    [string[]]
    [Parameter(Position = 5)]
    $Characteristic = "*",

    [Parameter(Position = 5, Mandatory = $false)]
    [nullable[boolean]]$PreferLTSC = $null
  )

  $c = LoadRepository
  try {
    if ($c[0] -eq $false) { return }

    $newFilter = New-Object SoftpaqRepositoryFile+SoftpaqRepositoryFilter
    $newFilter.platform = $Platform
    $newFilter.OperatingSystem = $Os

    if ($Os -eq "win10") {
      if ($OsVer) { $newFilter.OperatingSystem = "win10:$OsVer" }
      else { $newFilter.OperatingSystem = "win10:*" }
    }
    elseif ($Os -eq "win11") {
      if ($OsVer) { $newFilter.OperatingSystem = "win11:$OsVer" }
      else { $newFilter.OperatingSystem = "win11:*" }
    }

    $newFilter.Category = $Category
    $newFilter.ReleaseType = $ReleaseType
    $newFilter.characteristic = $Characteristic
    $newFilter.preferLTSC = $PreferLTSC

    $todelete = getFiltersWild $c[1] $newFilter
    if (-not $todelete) {
      Write-Verbose ("No matching filter to delete")
      return
    }

    if (-not $Yes.IsPresent) {
      Write-Host "The following filters will be deleted:" -ForegroundColor Cyan
      $todelete | ConvertTo-Json -Depth 2 | Write-Host -ForegroundColor Cyan
      $answer = Read-Host "Enter 'y' to continue: "
      if ($answer -ne "y") {
        Write-Host 'Aborted.'
        return }
    }

    $c[1].Filters = $c[1].Filters | Where-Object { $todelete -notcontains $_ }
    WriteRepositoryFile -obj $c[1]

    foreach ($f in $todelete) {
      Log "Removed filter $($f.platform) { os='$($f.operatingSystem)', category='$($f.category)', release='$($f.releaseType), characteristic='$($f.characteristic)' }"
    }
  }
  catch
  {
    err ("Could not remove filter from repository: $($_.Exception.Message)")
  }
}

<#
.SYNOPSIS
  Retrieves the current repository definition

.DESCRIPTION
  This command retrieves the current repository definition as an object. This command must be executed inside an initialized repository.
  
.EXAMPLE
    $myrepository = Get-RepositoryInfo
    
.LINK
  [Initialize-Repository](https://developers.hp.com/hp-client-management/doc/Initialize-Repository)

.LINK
  [Add-RepositoryFilter](https://developers.hp.com/hp-client-management/doc/Add-RepositoryFilter)

.LINK
  [Remove-RepositoryFilter](https://developers.hp.com/hp-client-management/doc/Remove-RepositoryFilter)

.LINK
  [Invoke-RepositorySync](https://developers.hp.com/hp-client-management/doc/Invoke-RepositorySync)

.LINK
  [Invoke-RepositoryCleanup](https://developers.hp.com/hp-client-management/doc/Invoke-RepositoryCleanup)

.LINK
  [Set-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Set-RepositoryNotificationConfiguration)

.LINK
  [Clear-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Clear-RepositoryNotificationConfiguration)

.LINK 
  [Get-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Get-RepositoryNotificationConfiguration)

.LINK 
  [Show-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Show-RepositoryNotificationConfiguration)

.LINK
  [Add-RepositorySyncFailureRecipient](https://developers.hp.com/hp-client-management/doc/Add-RepositorySyncFailureRecipient)

.LINK
  [Remove-RepositorySyncFailureRecipient](https://developers.hp.com/hp-client-management/doc/Remove-RepositorySyncFailureRecipient)

.LINK
  [Test-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Test-RepositoryNotificationConfiguration)
#>
function Get-RepositoryInfo ()
{
  [CmdletBinding(HelpUri = "https://developers.hp.com/hp-client-management/doc/Get-RepositoryInfo")]
  param()

  $c = LoadRepository
  try {
    if (-not $c[0]) { return }
    $c[1]
  }
  catch
  {
    err ("Could not get repository info: $($_.Exception.Message)")
  }
}

<#
.SYNOPSIS
  Synchronizes the current repository and generates a report that includes information about the repository 

.DESCRIPTION
  This command performs a synchronization on the current repository by downloading the latest SoftPaqs associated with the repository filters and creates a repository report in a format (default .CSV) set via the Set-RepositoryConfiguration command. 

  This command may be scheduled via task manager to run on a schedule. You can define a notification email via the Set-RepositoryNotificationConfiguration command to receive any failure notifications during unattended operation.

  This command may be followed by the Invoke-RepositoryCleanup command to remove any obsolete SoftPaqs from the repository.

  Please note that the Invoke-RepositorySync command is not supported in WinPE. 

.PARAMETER Quiet
  If specified, this command will suppress progress messages during execution. 

.PARAMETER ReferenceUrl
  Specifies an alternate location for the HP Image Assistant (HPIA) Reference files. This URL must be https. The Reference files are expected to be at the location pointed to by this URL inside a directory named after the platform ID you want a SoftPaq list for.
  Using system ID 83b2, OS Win10, and OSVer 2009 reference files as an example, this command will call the Get-SoftpaqList command to find the corresponding files in: $ReferenceUrl/83b2/83b2_64_10.0.2009.cab.
  If not specified, 'https://hpia.hpcloud.hp.com/ref/' is used by default, and fallback is set to 'https://ftp.hp.com/pub/caps-softpaq/cmit/imagepal/ref/'.

.EXAMPLE
  Invoke-RepositorySync -Quiet

.LINK
  [Initialize-Repository](https://developers.hp.com/hp-client-management/doc/Initialize-Repository)

.LINK
  [Add-RepositoryFilter](https://developers.hp.com/hp-client-management/doc/Add-RepositoryFilter)

.LINK
  [Remove-RepositoryFilter](https://developers.hp.com/hp-client-management/doc/Remove-RepositoryFilter)

.LINK
  [Get-RepositoryInfo](https://developers.hp.com/hp-client-management/doc/Get-RepositoryInfo)

.LINK
  [Invoke-RepositoryCleanup](https://developers.hp.com/hp-client-management/doc/Invoke-RepositoryCleanup)

.LINK
  [Set-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Set-RepositoryNotificationConfiguration)

.LINK
  [Clear-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Clear-RepositoryNotificationConfiguration)

.LINK 
  [Get-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Get-RepositoryNotificationConfiguration)

.LINK 
  [Show-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Show-RepositoryNotificationConfiguration)

.LINK
  [Add-RepositorySyncFailureRecipient](https://developers.hp.com/hp-client-management/doc/Add-RepositorySyncFailureRecipient)

.LINK
  [Remove-RepositorySyncFailureRecipient](https://developers.hp.com/hp-client-management/doc/Remove-RepositorySyncFailureRecipient)

.LINK
  [Test-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Test-RepositoryNotificationConfiguration)
#>
function Invoke-RepositorySync
{
  [CmdletBinding(HelpUri = "https://developers.hp.com/hp-client-management/doc/Invoke-RepositorySync")]
  param(
    [Parameter(Position = 0,Mandatory = $false)]
    [switch]$Quiet = $false,

    [Alias('Url')]
    [Parameter(Position = 1,Mandatory = $false)]
    [string]$ReferenceUrl = "https://hpia.hpcloud.hp.com/ref"
  )

  # only allow https or file paths with or without file:// URL prefix
  if ($ReferenceUrl -and -not ($ReferenceUrl.StartsWith("https://",$true,$null) -or [System.IO.Directory]::Exists($ReferenceUrl) -or $ReferenceUrl.StartsWith("file//:",$true,$null))) {
    throw [System.ArgumentException]"Only HTTPS or valid existing directory paths are supported."
  }

  if (-not $ReferenceUrl.EndsWith('/')) {
    $ReferenceUrl = $ReferenceUrl + "/"
  }

  # Fallback to FTP only if ReferenceUrl is the default, and not when a custom ReferenceUrl is specified
  if ($ReferenceUrl -eq 'https://hpia.hpcloud.hp.com/ref/') {
    $referenceFallbackUrL = 'https://ftp.hp.com/pub/caps-softpaq/cmit/imagepal/ref/'
  }
  else {
    $referenceFallbackUrL = ''
  }

  $repo = LoadRepository
  try {
    $cwd = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath((Get-Location))
    $cacheDir = Join-Path -Path $cwd -ChildPath ".repository"
    $cacheDirOffline = $cacheDir + "\cache\offline"
    $reportDir = $cacheDir

    # return if repository is not initialized
    if ($repo[0] -eq $false) { return }

    # return if repository is initialized but no filters added
    $filters = $repo[1].Filters
    if ($filters.Count -eq 0) {
      Write-Verbose "Repository has no filters defined - terminating."
      Write-Verbose ("Flushing the list of markers")
      FlushMarks
      return
    }

    $platformGroups = $filters | Group-Object -Property platform
    $normalized = @()

    foreach ($pobj in $platformGroups)
    {

      $items = $pobj.Group

      if ($items | Where-Object -Property operatingSystem -EQ -Value "*") {
        $items | ForEach-Object { $_.OperatingSystem = "*" }
      }

      if ($items | Where-Object -Property category -EQ -Value "*") {
        $items | ForEach-Object { $_.Category = "*" }
      }

      if ($items | Where-Object -Property releaseType -EQ -Value "*") {
        $items | ForEach-Object { $_.ReleaseType = "*" }
      }

      if ($items | Where-Object -Property characteristic -EQ -Value "*") {
        $items | ForEach-Object { $_.characteristic = "*" }
      }

      $normalized += $items | sort -Unique -Property operatingSystem,category,releaseType,characteristic
    }

    $softpaqlist = @()
    Log "Repository sync has started"
    $softpaqListCmd = @{}


    # build the list of SoftPaqs to download
    foreach ($c in $normalized) {
      Write-Verbose ($c | Format-List | Out-String)

      if (Get-HPDeviceDetails -Platform $c.platform -Url $ReferenceUrl)
      {
        $softpaqListCmd.platform = $c.platform.ToLower()
        $softpaqListCmd.Quiet = $Quiet
        $softpaqListCmd.verbose = $VerbosePreference

        Write-Verbose ("Working on a rule for platform $($softpaqListCmd.platform)")

        if ($c.OperatingSystem.StartsWith("win10:"))
        {
          $split = $c.OperatingSystem -split ':'
          $softpaqListCmd.OS = $split[0]
          $softpaqListCmd.osver = $split[1]
        }
        elseif ($c.OperatingSystem -eq "win10")
        {
          $softpaqListCmd.OS = "win10"
          $softpaqListCmd.osver = GetCurrentOSVer
        }
        elseif ($c.OperatingSystem.StartsWith("win11:"))
        {
          $split = $c.OperatingSystem -split ':'
          $softpaqListCmd.OS = $split[0]
          $softpaqListCmd.osver = $split[1]
        }
        elseif ($c.OperatingSystem -eq "win11")
        {
          $softpaqListCmd.OS = "win11"
          $softpaqListCmd.osver = GetCurrentOSVer
        }
        elseif ($c.OperatingSystem -ne "*")
        {
          $softpaqListCmd.OS = $c.OperatingSystem
          #$softpaqListCmd.osver = $null
        }

        if ($c.characteristic -ne "*")
        {
          $softpaqListCmd.characteristic = $c.characteristic.ToUpper().Split()
          Write-Verbose "Filter-characteristic:$($softpaqListCmd.characteristic)"
        }

        if ($c.ReleaseType -ne "*")
        {
          $softpaqListCmd.ReleaseType = $c.ReleaseType.Split()
          Write-Verbose "Filter-releaseType:$($softpaqListCmd.releaseType)"
        }
        if ($c.Category -ne "*")
        {
          $softpaqListCmd.Category = $c.Category.Split()
          Write-Verbose "Filter-category:$($softpaqListCmd.category)"
        }
        if ($c.preferLTSC -eq $true)
        {
          $softpaqListCmd.PreferLTSC = $true
          Write-Verbose "Filter-preferLTSC:$($softpaqListCmd.PreferLTSC)"
        }

        Log "Reading the softpaq list for platform $($softpaqListCmd.platform)"
        Write-Verbose "Trying to get SoftPaqs from $ReferenceUrl"
        $results = Get-SoftpaqList @softpaqListCmd -cacheDir $cacheDir -maxRetries $repo[1].settings.ExclusiveLockMaxRetries -ReferenceUrl $ReferenceUrl -AddHttps
        Log "softpaq list for platform $($softpaqListCmd.platform) created"
        $softpaqlist += $results


        $OfflineCacheMode = $repo[1].settings.OfflineCacheMode
        if ($OfflineCacheMode -eq "Enable") {

          # keep the download order of PlatformList, Advisory data and Knowledge Base as is to maintain unit tests
          $baseurl = $ReferenceUrl
          $url = $baseurl + "platformList.cab"
          $filename = "platformList.cab"
          Write-Verbose "Trying to download PlatformList... $url"
          $PlatformList = $null
          try {
            $PlatformList = Get-HPPrivateOfflineCacheFiles -url $url -FileName $filename -cacheDirOffline $cacheDirOffline -Expand -Verbose:$VerbosePreference
            Write-Verbose "Finish downloading PlatformList - $PlatformList"
          }
          catch {
            if ($referenceFallbackUrL) {
              $url = "$($referenceFallbackUrL)platformList.cab"
              Write-Verbose "Trying to download PlatformList from FTP... $url"
              try {
                $PlatformList = Get-HPPrivateOfflineCacheFiles -url $url -FileName $filename -cacheDirOffline $cacheDirOffline -Expand -Verbose:$VerbosePreference
              }
              catch {
                Write-Verbose "Error downloading $url. $($_.Exception.Message)"
                # Continue the execution with empty PlatformList file
                $PlatformList = ""
              }
            }
            if (-not $PlatformList) {
              $exception = $_.Exception
              switch ($repo[1].settings.OnRemoteFileNotFound) {
                "LogAndContinue" {
                  [string]$data = formatSyncErrorMessageAsHtml $exception
                  Log ($data -split "`n")
                  send "Softpaq repository synchronization error" $data
                }
                # "Fail"
                default {
                  throw $exception
                }
              }
            }
          }

          # download Advisory data
          $url = $baseurl + "$($softpaqListCmd.platform)/$($softpaqListCmd.platform)_cds.cab"
          $cacheDirAdvisory = $cacheDirOffline + "\$($softpaqListCmd.platform)"
          $filename = "$($softpaqListCmd.platform)_cds.cab"
          Write-Verbose "Trying to download Advisory Data Files... $url"
          $AdvisoryFile = $null
          try {
            $AdvisoryFile = Get-HPPrivateOfflineCacheFiles -url $url -FileName $filename -cacheDirOffline $cacheDirAdvisory -Expand -Verbose:$VerbosePreference
            Write-Verbose "Finish downloading Advisory Data Files - $AdvisoryFile"
          }
          catch {
            if ($referenceFallbackUrL) {
              $url = "$($referenceFallbackUrL)$($softpaqListCmd.platform)/$($softpaqListCmd.platform)_cds.cab"
              Write-Verbose "Trying to download Advisory Data from FTP... $url"
              #$cacheDirAdvisory = $cacheDirOffline + "\$($softpaqListCmd.platform)"
              #$filename = "$($softpaqListCmd.platform)_cds.cab"
              try {
                $AdvisoryFile = Get-HPPrivateOfflineCacheFiles -url $url -FileName $filename -cacheDirOffline $cacheDirAdvisory -Expand -Verbose:$VerbosePreference
                Write-Verbose "Finish downloading Advisory Data Files - $AdvisoryFile"
              }
              catch {
                Write-Verbose "Error downloading $url. $($_.Exception.Message)"
                # Continue the execution with empty advisory file
                $AdvisoryFile = ""
              }
            }
            if (-not $AdvisoryFile) {
              $exception = $_.Exception
              switch ($repo[1].settings.OnRemoteFileNotFound) {
                "LogAndContinue" {
                  [string]$data = formatSyncErrorMessageAsHtml $exception
                  Log ($data -split "`n")
                  send "Softpaq repository synchronization error" $data
                }
                # "Fail"
                default {
                  Write-Warning "Advisory file does not exist for platform $($softpaqListCmd.platform). $($exception.Message)."
                  #throw $exception # do not fail the whole repository sync when advisory file is missing
                }
              }
            }
          }

          # download Knowledge Base
          $url = $baseurl + "../kb/common/latest.cab"
          $cacheDirKb = $cacheDirOffline + "\kb\common"
          $filename = "latest.cab"
          Write-Verbose "Trying to download Knowledge Base... $url"
          $KnowledgeBase = $null
          try {
            $KnowledgeBase = Get-HPPrivateOfflineCacheFiles -url $url -FileName $filename -cacheDirOffline $cacheDirKb -Verbose:$VerbosePreference
            Write-Verbose "Finish downloading Knowledge Base - $KnowledgeBase"
          }
          catch {
            if ($referenceFallbackUrL) {
              $url = "$($referenceFallbackUrL)../kb/common/latest.cab"
              Write-Verbose "Trying to download Knowledge Base from FTP... $url"
              #$cacheDirKb = $cacheDirOffline + "\kb\common"
              #$filename = "latest.cab"
              try {
                $KnowledgeBase = Get-HPPrivateOfflineCacheFiles -url $url -FileName $filename -cacheDirOffline $cacheDirKb -Verbose:$VerbosePreference
              }
              catch {
                Write-Verbose "Error downloading $url. $($_.Exception.Message)"
                # Continue the execution with empty KnowledgeBase file
                $KnowledgeBase = ""
              }
              Write-Verbose "Finish downloading Knowledge Base - $KnowledgeBase"
            }
            if (-not $KnowledgeBase) {
              $exception = $_.Exception
              switch ($repo[1].settings.OnRemoteFileNotFound) {
                "LogAndContinue" {
                  [string]$data = formatSyncErrorMessageAsHtml $exception
                  Log ($data -split "`n")
                  send "Softpaq repository synchronization error" $data
                }
                # "Fail"
                default {
                  throw $exception
                }
              }
            }
          }
        }
      }
      else {
        Write-Host -ForegroundColor Cyan "Platform $($c.platform) doesn't exist. Please add a valid platform."
        Write-LogWarning "Platform $($c.platform) is not valid. Skipping it."
      }
    }

    Write-Verbose ("Done with the list, repository is $($softpaqlist.Count) softpaqs.")
    [array]$softpaqlist = @($softpaqlist | Sort-Object -Unique -Property Id)
    Write-Verbose ("After trimming duplicates, we have $($softpaqlist.Count) softpaqs.")

    Write-Verbose ("Flushing the list of markers")
    FlushMarks
    Write-Verbose ("Writing new marks")

    # generate .mark file for each SoftPaq to be downloaded
    foreach ($sp in $softpaqList) {
      $number = $sp.id.ToLower().TrimStart("sp")
      TouchFile -File ".repository/mark/$number.mark"
    }

    Write-Verbose ("Starting download")
    $downloadCmd = @{}
    $downloadCmd.Quiet = $quiet
    $downloadCmd.Verbose = $VerbosePreference

    Log "Download has started for $($softpaqlist.Count) softpaqs."
    foreach ($sp in $softpaqlist)
    {
      $downloadCmd.Number = $sp.id.ToLower().TrimStart("sp")
      $downloadCmd.Url = $sp.url -Replace "/$($sp.id).exe$",''
      Write-Verbose "Working on data for softpaq $($downloadCmd.number)"
      try {
        Log "Start downloading files for sp$($downloadCmd.number)."
        DownloadSoftpaq -DownloadSoftpaqCmd $downloadCmd -MaxRetries $repo[1].settings.ExclusiveLockMaxRetries -Verbose:$VerbosePreference

        if ($OfflineCacheMode -eq "Enable") {
          Log ("    sp$($downloadCmd.number).html - Downloading Release Notes.")
          $ReleaseNotesurl = Get-HPPrivateItemUrl $downloadCmd.number "html"
          $target = "sp$($downloadCmd.number).html"
          $targetfile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($target)
          Invoke-HPPrivateDownloadFile -url $ReleaseNotesurl -Target $targetfile
          Log ("    sp$($downloadCmd.number).html - Done Downloading Release Notes.")
        }
        Log "Finish downloading files for sp$($downloadCmd.number)."
      }
      catch {
        $exception = $_.Exception

        switch ($repo[1].settings.OnRemoteFileNotFound)
        {
          "LogAndContinue" {
            [string]$data = formatSyncErrorMessageAsHtml $exception
            Log ($data -split "`n")
            send "Softpaq repository synchronization error" $data
          }
          # "Fail"
          default {
            Write-Output "Error downloading $($downloadCmd.Url). $($exception.Message)"
            throw $exception
          }
        }
      }
    }

    Log "Repository sync has ended"
    Write-Verbose "Repository Sync has ended."

    Log "Repository Report creation started"
    Write-Verbose "Repository Report creation started."

    try {
      # get the configuration set for repository report if any
      $RepositoryReport = $repo[1].settings.RepositoryReport
      if ($RepositoryReport) {
        $Format = $RepositoryReport
        New-RepositoryReport -Format $Format -RepositoryPath "$cwd" -OutputFile "$cwd\.repository\Contents.$Format"
        Log "Repository Report created as Contents.$Format"
        Write-Verbose "Repository Report created as Content.$Format."
      }
    }
    catch [System.IO.FileNotFoundException]{
      Write-Verbose "No data available to create Repository Report as directory '$(Get-Location)' does not contain any CVA files."
      Log "No data available to create Repository Report as directory '$(Get-Location)' does not contain any CVA files."
    }
    catch {
      Write-Verbose "Error in creating Repository Report"
      Log "Error in creating Repository Report."
    }
  }
  catch
  {
    err "Repository synchronization failed: $($_.Exception.Message)" $true
    [string]$data = formatSyncErrorMessageAsHtml $_.Exception
    Log ($data -split "`n")
    send "Softpaq repository synchronization error" $data
  }
}

function formatSyncErrorMessageAsHtml ($exception)
{
  [string]$data = "An error occurred during softpaq synchronization.`n`n";
  $data += "The error was: <em>$($exception.Message)</em>`n"
  $data += "`nDetails:`n<pre>"
  $data += "<hr/>"
  $data += ($exception | Format-List -Force | Out-String)
  $data += "</pre>"
  $data += "<hr/>"
  $data
}

<#
.SYNOPSIS
    Removes obsolete SoftPaqs from the current repository
  
.DESCRIPTION
  This command removes SoftPaqs from the current repository that are labeled as obsolete. These may be SoftPaqs that have been replaced
  by newer versions, or SoftPaqs that no longer match the active repository filters.

.EXAMPLE
    Invoke-RepositoryCleanup

.LINK
  [Initialize-Repository](https://developers.hp.com/hp-client-management/doc/Initialize-Repository)

.LINK
  [Add-RepositoryFilter](https://developers.hp.com/hp-client-management/doc/Add-RepositoryFilter)

.LINK
  [Remove-RepositoryFilter](https://developers.hp.com/hp-client-management/doc/Remove-RepositoryFilter)

.LINK
  [Get-RepositoryInfo](https://developers.hp.com/hp-client-management/doc/Get-RepositoryInfo)

.LINK
  [Invoke-RepositorySync](https://developers.hp.com/hp-client-management/doc/Invoke-RepositorySync)

.LINK
  [Set-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Set-RepositoryNotificationConfiguration)

.LINK
  [Clear-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Clear-RepositoryNotificationConfiguration)

.LINK 
  [Get-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Get-RepositoryNotificationConfiguration)

.LINK 
  [Show-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Show-RepositoryNotificationConfiguration)

.LINK
  [Add-RepositorySyncFailureRecipient](https://developers.hp.com/hp-client-management/doc/Add-RepositorySyncFailureRecipient)

.LINK
  [Remove-RepositorySyncFailureRecipient](https://developers.hp.com/hp-client-management/doc/Remove-RepositorySyncFailureRecipient)

.LINK
  [Test-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Test-RepositoryNotificationConfiguration)

#>
function Invoke-RepositoryCleanup
{
  [CmdletBinding(HelpUri = "https://developers.hp.com/hp-client-management/doc/Invoke-RepositoryCleanup")]
  param()
  $repo = LoadRepository
  Log ("Beginning repository cleanup")
  $deleted = 0

  try {
    Get-ChildItem "." -File | ForEach-Object {
      $name = $_.Name.ToLower().TrimStart("sp").Split('.')[0]
      if ($name -ne $null) {
        if (-not (Test-Path ".repository/mark/$name.mark" -PathType Leaf))
        {
          Write-Verbose "Deleting orphaned file $($_.Name)"
          Remove-Item $_.Name
          $deleted++
        }
        #else {
        #  Write-Verbose "Softpaq $($_.Name) is still needed."
        #}
      }
    }
    Log ("Completed repository cleanup, deleted $deleted files.")
  }
  catch {
    err ("Could not clean repository: $($_.Exception.Message)")
  }
}

<#
.SYNOPSIS
  Sets the repository notification configuration in the current repository

.DESCRIPTION
  This command defines a notification Simple Mail Transfer Protocol (SMTP) server (and optionally, port) for an email server to be used to send failure notifications during unattended synchronization via the Invoke-RepositorySync command. 

  One or more recipients can then be added via the Add-RepositorySyncFailureRecipient command. 

  This command must be invoked inside a directory initialized as a repository using the Initialize-Repository command. 


.PARAMETER Server
  Specifies the server name (or IP) for the outgoing mail (SMTP) server

.PARAMETER Port
  Specifies a port for the SMTP server. If not specified, the default IANA-assigned port 25 will be used.

.PARAMETER Tls
  Specifies the usage for Transport Layer Security (TLS). The value may be 'true', 'false', or 'auto'. 'Auto' will automatically set TLS to true when the port is changed to a value different than 25. By default, TLS is false. Please note that TLS is the successor protocol to Secure Sockets Layer (SSL).

.PARAMETER UserName
  Specifies the SMTP server username for authenticated SMTP servers. If not specified, connection will be made without authentication.

.PARAMETER Password
  Specifies the SMTP server password for authenticated SMTP servers.
  
.PARAMETER From
  Specifies the email address from which the notification will appear to originate. Note that some servers may accept emails from specified domains only or require the email address to match the username.

.PARAMETER FromName
  Specifies the from address display name

.PARAMETER RemoveCredentials
  If specified, this command will remove the SMTP server credentials without removing the entire mail server configuration.

.EXAMPLE
  Set-RepositoryNotificationConfiguration smtp.mycompany.com

.LINK
  [Initialize-Repository](https://developers.hp.com/hp-client-management/doc/Initialize-Repository)

.LINK
  [Add-RepositoryFilter](https://developers.hp.com/hp-client-management/doc/Add-RepositoryFilter)

.LINK
  [Remove-RepositoryFilter](https://developers.hp.com/hp-client-management/doc/Remove-RepositoryFilter)

.LINK
  [Get-RepositoryInfo](https://developers.hp.com/hp-client-management/doc/Get-RepositoryInfo)

.LINK
  [Invoke-RepositorySync](https://developers.hp.com/hp-client-management/doc/Invoke-RepositorySync)

.LINK
  [Invoke-RepositoryCleanup](https://developers.hp.com/hp-client-management/doc/Invoke-RepositoryCleanup)

.LINK
  [Clear-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Clear-RepositoryNotificationConfiguration)

.LINK 
  [Get-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Get-RepositoryNotificationConfiguration)

.LINK 
  [Show-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Show-RepositoryNotificationConfiguration)

.LINK
  [Add-RepositorySyncFailureRecipient](https://developers.hp.com/hp-client-management/doc/Add-RepositorySyncFailureRecipient)

.LINK
  [Remove-RepositorySyncFailureRecipient](https://developers.hp.com/hp-client-management/doc/Remove-RepositorySyncFailureRecipient)

.LINK
  [Test-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Test-RepositoryNotificationConfiguration)

#>
function Set-RepositoryNotificationConfiguration
{
  [CmdletBinding(HelpUri = "https://developers.hp.com/hp-client-management/doc/Set-RepositoryNotificationConfiguration")]
  param(
    [Parameter(Position = 0,Mandatory = $false)]
    [string]
    [ValidatePattern("^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$")]
    $Server = $null,

    [Parameter(Position = 1,Mandatory = $false)]
    [ValidateRange(1,65535)]
    [int]
    $Port = 0,

    [Parameter(Position = 2,Mandatory = $false)]
    [string]
    [ValidateSet('true','false','auto')]
    $Tls = $null,

    [Parameter(Position = 3,Mandatory = $false)]
    [string]
    $Username = $null,

    [Parameter(Position = 4,Mandatory = $false)]
    [string]
    $Password = $null,

    [Parameter(Position = 5,Mandatory = $false)]
    [string]
    [ValidatePattern("^\w+([-+.']\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*$")]
    $From = $null,

    [Parameter(Position = 6,Mandatory = $false)]
    [string]
    $FromName = $null,

    [Parameter(Position = 7,Mandatory = $false)]
    [switch]
    $RemoveCredentials
  )

  Write-Verbose "Beginning notification configuration update"

  if ($RemoveCredentials.IsPresent -and ([string]::IsNullOrEmpty($UserName) -eq $false -or [string]::IsNullOrEmpty($Password) -eq $false))
  {
    err ("-removeCredentials may not be specified with -username or -password")
    return
  }

  $c = LoadRepository
  try {
    if (-not $c[0]) { return }

    Write-Verbose "Applying configuration"
    if ([string]::IsNullOrEmpty($Server) -eq $false) {
      Write-Verbose ("Setting SMTP Server to: $Server")
      $c[1].Notifications.server = $Server
    }

    if ($Port) {
      Write-Verbose ("Setting SMTP Server port to: $Port")
      $c[1].Notifications.port = $Port
    }

    if (-not [string]::IsNullOrEmpty($UserName)) {
      Write-Verbose ("Setting SMTP server credential(username) to: $UserName")
      $c[1].Notifications.UserName = $UserName
    }

    if (-not [string]::IsNullOrEmpty($Password)) {
      Write-Verbose ("Setting SMTP server credential(password) to: (redacted)")
      $c[1].Notifications.Password = ConvertTo-SecureString $Password -Force -AsPlainText | ConvertFrom-SecureString
    }

    if ($RemoveCredentials.IsPresent)
    {
      Write-Verbose ("Clearing credentials from notification configuration")
      $c[1].Notifications.UserName = $null
      $c[1].Notifications.Password = $null
    }

    switch ($Tls)
    {
      "auto" {
        if ($Port -ne 25) { $c[1].Notifications.tls = $true }
        else { $c[1].Notifications.tls = $false }
        Write-Verbose ("SMTP server SSL auto-calculated to: $($c[1].Notifications.tls)")
      }

      "true" {
        $c[1].Notifications.tls = $true
        Write-Verbose ("Setting SMTP SSL to: $($c[1].Notifications.tls)")
      }
      "false" {
        $c[1].Notifications.tls = $false
        Write-Verbose ("Setting SMTP SSL to: $($c[1].Notifications.tls)")
      }
    }
    if (-not [string]::IsNullOrEmpty($From)) {
      Write-Verbose ("Setting Mail from address to: $From")
      $c[1].Notifications.from = $From }
    if (-not [string]::IsNullOrEmpty($FromName)) {
      Write-Verbose ("Setting Mail from displayname to: $FromName")
      $c[1].Notifications.fromname = $FromName }

    WriteRepositoryFile -obj $c[1]
    Log ("Updated notification configuration")
  }
  catch {
    err ("Failed to modify repository configuration: $($_.Exception.Message)")
  }
}

<#
.SYNOPSIS
    Clears the repository notification configuration from the current repository

.DESCRIPTION
  This command removes notification configuration from the current repository, and as a result, notifications are turned off.
  This command must be invoked inside a directory initialized as a repository using the Initialize-Repository command.
  Please note that notification configuration must have been defined via the Set-RepositoryNotificationConfiguration command for this command to have any effect.  

.LINK
  [Initialize-Repository](https://developers.hp.com/hp-client-management/doc/Initialize-Repository)

.LINK
  [Add-RepositoryFilter](https://developers.hp.com/hp-client-management/doc/Add-RepositoryFilter)

.LINK
  [Remove-RepositoryFilter](https://developers.hp.com/hp-client-management/doc/Remove-RepositoryFilter)

.LINK
  [Get-RepositoryInfo](https://developers.hp.com/hp-client-management/doc/Get-RepositoryInfo)

.LINK
  [Invoke-RepositorySync](https://developers.hp.com/hp-client-management/doc/Invoke-RepositorySync)

.LINK
  [Invoke-RepositoryCleanup](https://developers.hp.com/hp-client-management/doc/Invoke-RepositoryCleanup)

.LINK
  [Set-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Set-RepositoryNotificationConfiguration)

.LINK 
  [Get-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Get-RepositoryNotificationConfiguration)

.LINK 
  [Show-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Show-RepositoryNotificationConfiguration)

.LINK
  [Add-RepositorySyncFailureRecipient](https://developers.hp.com/hp-client-management/doc/Add-RepositorySyncFailureRecipient)

.LINK
  [Remove-RepositorySyncFailureRecipient](https://developers.hp.com/hp-client-management/doc/Remove-RepositorySyncFailureRecipient)

.LINK
  [Test-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Test-RepositoryNotificationConfiguration)

.EXAMPLE
  Clear-RepositoryNotificationConfiguration

#>
function Clear-RepositoryNotificationConfiguration ()
{
  [CmdletBinding(HelpUri = "https://developers.hp.com/hp-client-management/doc/Clear-RepositoryNotificationConfiguration")]
  param()
  Log "Clearing notification configuration"

  $c = LoadRepository
  try {
    if (-not $c[0]) { return }
    $c[1].Notifications = $null
    WriteRepositoryFile -obj $c[1]
    Write-Verbose ("Ok.")
  }
  catch {
    err ("Failed to modify repository configuration: $($_.Exception.Message)")
  }
}

<#
.SYNOPSIS
  Retrieves the current notification configuration

.DESCRIPTION
  This command retrieves the current notification configuration as an object. 
  This command must be invoked inside a directory initialized as a repository using the Initialize-Repository command. 
  The current notification configuration must be set via the Set-RepositoryNotificationConfiguration command. 

.LINK
  [Initialize-Repository](https://developers.hp.com/hp-client-management/doc/Initialize-Repository)

.LINK
  [Add-RepositoryFilter](https://developers.hp.com/hp-client-management/doc/Add-RepositoryFilter)

.LINK
  [Remove-RepositoryFilter](https://developers.hp.com/hp-client-management/doc/Remove-RepositoryFilter)

.LINK
  [Get-RepositoryInfo](https://developers.hp.com/hp-client-management/doc/Get-RepositoryInfo)

.LINK
  [Invoke-RepositorySync](https://developers.hp.com/hp-client-management/doc/Invoke-RepositorySync)

.LINK
  [Invoke-RepositoryCleanup](https://developers.hp.com/hp-client-management/doc/Invoke-RepositoryCleanup)

.LINK
  [Set-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Set-RepositoryNotificationConfiguration)

.LINK 
  [Clear-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Clear-RepositoryNotificationConfiguration)

.LINK 
  [Show-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Show-RepositoryNotificationConfiguration)

.LINK
  [Add-RepositorySyncFailureRecipient](https://developers.hp.com/hp-client-management/doc/Add-RepositorySyncFailureRecipient)

.LINK
  [Test-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Test-RepositoryNotificationConfiguration)

.EXAMPLE
  $config = Get-RepositoryNotificationConfiguration


#>
function Get-RepositoryNotificationConfiguration ()
{
  [CmdletBinding(HelpUri = "https://developers.hp.com/hp-client-management/doc/Get-RepositoryNotificationConfiguration")]
  param()

  $c = LoadRepository
  if ((-not $c[0]) -or (-not $c[1].Notifications))
  {
    return $null
  }
  return $c[1].Notifications
}


<#
.SYNOPSIS
    Displays the current notification configuration onto the screen


.DESCRIPTION
  This command retrieves the current notification configuration as user-friendly screen output.
  This command must be invoked inside a directory initialized as a repository using the Initialize-Repository command.
  The current notification configuration must be set via the Set-RepositoryNotificationConfiguration command. 

.LINK
  [Initialize-Repository](https://developers.hp.com/hp-client-management/doc/Initialize-Repository)

.LINK
  [Add-RepositoryFilter](https://developers.hp.com/hp-client-management/doc/Add-RepositoryFilter)

.LINK
  [Remove-RepositoryFilter](https://developers.hp.com/hp-client-management/doc/Remove-RepositoryFilter)

.LINK
  [Get-RepositoryInfo](https://developers.hp.com/hp-client-management/doc/Get-RepositoryInfo)

.LINK
  [Invoke-RepositorySync](https://developers.hp.com/hp-client-management/doc/Invoke-RepositorySync)

.LINK
  [Invoke-RepositoryCleanup](https://developers.hp.com/hp-client-management/doc/Invoke-RepositoryCleanup)

.LINK
  [Set-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Set-RepositoryNotificationConfiguration)

.LINK 
  [Clear-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Clear-RepositoryNotificationConfiguration)

.LINK 
  [Get-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Get-RepositoryNotificationConfiguration)

.LINK
  [Add-RepositorySyncFailureRecipient](https://developers.hp.com/hp-client-management/doc/Add-RepositorySyncFailureRecipient)

.LINK
  [Test-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Test-RepositoryNotificationConfiguration)

.EXAMPLE
  Show-RepositoryNotificationConfiguration
#>
function Show-RepositoryNotificationConfiguration ()
{
  [CmdletBinding(HelpUri = "https://developers.hp.com/hp-client-management/doc/Show-RepositoryNotificationConfiguration")]
  param()

  try {
    $c = Get-RepositoryNotificationConfiguration
    if (-not $c)
    {
      err ("Notifications are not configured.")
      return
    }

    if (-not [string]::IsNullOrEmpty($c.UserName)) {
      Write-Host "Notification server: smtp://$($c.username):<password-redacted>@$($c.server):$($c.port)"
    }
    else {
      Write-Host "Notification server: smtp://$($c.server):$($c.port)"
    }
    Write-Host "Email will arrive from $($c.from) with name `"$($c.fromname)`""

    if ((-not $c.addresses) -or (-not $c.addresses.Count))
    {
      Write-Host "There are no recipients configured"
      return
    }
    foreach ($r in $c.addresses)
    {
      Write-Host "Recipient: $r"
    }
  }
  catch {
    err ("Failed to read repository configuration: $($_.Exception.Message)")
  }

}

<#
.SYNOPSIS
  Adds a recipient to the list of recipients to receive failure notification emails for the current repository

.DESCRIPTION
  This command adds a recipient via an email address to the list of recipients to receive failure notification emails for the current repository. If any failure occurs, notifications will be sent to this email address.

  This command must be invoked inside a directory initialized as a repository using the Initialize-Repository command.

.PARAMETER To
  Specifies the email address to add as a recipient of the failure notifications 

.LINK
  [Initialize-Repository](https://developers.hp.com/hp-client-management/doc/Initialize-Repository)

.LINK
  [Add-RepositoryFilter](https://developers.hp.com/hp-client-management/doc/Add-RepositoryFilter)

.LINK
  [Remove-RepositoryFilter](https://developers.hp.com/hp-client-management/doc/Remove-RepositoryFilter)

.LINK
  [Get-RepositoryInfo](https://developers.hp.com/hp-client-management/doc/Get-RepositoryInfo)

.LINK
  [Invoke-RepositorySync](https://developers.hp.com/hp-client-management/doc/Invoke-RepositorySync)

.LINK
  [Invoke-RepositoryCleanup](https://developers.hp.com/hp-client-management/doc/Invoke-RepositoryCleanup)

.LINK
  [Set-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Set-RepositoryNotificationConfiguration)

.LINK 
  [Clear-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Clear-RepositoryNotificationConfiguration)

.LINK 
  [Get-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Get-RepositoryNotificationConfiguration)

.LINK 
  [Show-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Show-RepositoryNotificationConfiguration)

.LINK
  [Remove-RepositorySyncFailureRecipient](https://developers.hp.com/hp-client-management/doc/Remove-RepositorySyncFailureRecipient)

.LINK
  [Test-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Test-RepositoryNotificationConfiguration)

.EXAMPLE
  Add-RepositorySyncFailureRecipient -to someone@mycompany.com

#>
function Add-RepositorySyncFailureRecipient ()
{
  [CmdletBinding(HelpUri = "https://developers.hp.com/hp-client-management/doc/Add-RepositorySyncFailureRecipient")]
  param(
    [Parameter(Position = 0,Mandatory = $true)]
    [ValidatePattern("^\w+([-+.']\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*$")]
    [string]
    $To
  )

  Log "Adding '$To' as a recipient."
  $c = LoadRepository
  try {
    if (-not $c[0]) { return }

    if (-not $c[1].Notifications) {
      err ("Notifications are not configured")
      return
    }

    if (-not $c[1].Notifications.addresses) {
      $c[1].Notifications.addresses = $()
    }

    $c[1].Notifications.addresses += $To.trim()
    $c[1].Notifications.addresses = $c[1].Notifications.addresses | Sort-Object -Unique
    WriteRepositoryFile -obj ($c[1] | Sort-Object -Unique)
  }
  catch {
    err ("Failed to modify repository configuration: $($_.Exception.Message)")
  }

}

<#
.SYNOPSIS
  Removes a recipient from the list of recipients that receive failure notification emails for the current repository


.DESCRIPTION
  This command removes an email address as a recipient for synchronization failure messages. 
  This command must be invoked inside a directory initialized as a repository using the Initialize-Repository command. 
  Notification configured via the Set-RepositoryNotificationConfiguration command. 

.PARAMETER To
  Specifies the email address to remove

.LINK
  [Initialize-Repository](https://developers.hp.com/hp-client-management/doc/Initialize-Repository)

.LINK
  [Add-RepositoryFilter](https://developers.hp.com/hp-client-management/doc/Add-RepositoryFilter)

.LINK
  [Remove-RepositoryFilter](https://developers.hp.com/hp-client-management/doc/Remove-RepositoryFilter)

.LINK
  [Get-RepositoryInfo](https://developers.hp.com/hp-client-management/doc/Get-RepositoryInfo)

.LINK
  [Invoke-RepositorySync](https://developers.hp.com/hp-client-management/doc/Invoke-RepositorySync)

.LINK
  [Invoke-RepositoryCleanup](https://developers.hp.com/hp-client-management/doc/Invoke-RepositoryCleanup)

.LINK
  [Set-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Set-RepositoryNotificationConfiguration)

.LINK 
  [Clear-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Clear-RepositoryNotificationConfiguration)

.LINK 
  [Get-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Get-RepositoryNotificationConfiguration)

.LINK 
  [Show-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Show-RepositoryNotificationConfiguration)

.LINK
  [Remove-RepositorySyncFailureRecipient](https://developers.hp.com/hp-client-management/doc/Remove-RepositorySyncFailureRecipient)

.LINK
  [Test-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Test-RepositoryNotificationConfiguration)

.EXAMPLE
  Remove-RepositorySyncFailureRecipient -to someone@mycompany.com

#>
function Remove-RepositorySyncFailureRecipient
{
  [CmdletBinding(HelpUri = "https://developers.hp.com/hp-client-management/doc/Remove-RepositorySyncFailureRecipient")]
  param(
    [Parameter(Position = 0,Mandatory = $true)]
    [ValidatePattern("^\w+([-+.']\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*$")]
    [string]
    $To
  )
  Log "Removing '$To' as a recipient."
  $c = LoadRepository
  try {
    if ($c[0] -eq $false) { return }

    if (-not $c[1].Notifications) {
      err ("Notifications are not configured")
      return
    }


    if (-not $c[1].Notifications.addresses) {
      $c[1].Notifications.addresses = $()
    }

    $c[1].Notifications.addresses = $c[1].Notifications.addresses | Where-Object { $_ -ne $To.trim() } | Sort-Object -Unique
    WriteRepositoryFile -obj ($c[1] | Sort-Object -Unique)
  }
  catch {
    err ("Failed to modify repository configuration: $($_.Exception.Message)")
  }
}


<#
.SYNOPSIS
  Tests the email notification configuration by sending a test email

.DESCRIPTION
  This command sends a test email using the current repository configuration and reports 
  any errors associated with the send process. This command is intended to debug the email server configuration.

.LINK
  [Initialize-Repository](https://developers.hp.com/hp-client-management/doc/Initialize-Repository)

.LINK
  [Add-RepositoryFilter](https://developers.hp.com/hp-client-management/doc/Add-RepositoryFilter)

.LINK
  [Remove-RepositoryFilter](https://developers.hp.com/hp-client-management/doc/Remove-RepositoryFilter)

.LINK
  [Get-RepositoryInfo](https://developers.hp.com/hp-client-management/doc/Get-RepositoryInfo)

.LINK
  [Invoke-RepositorySync](https://developers.hp.com/hp-client-management/doc/Invoke-RepositorySync)

.LINK
  [Invoke-RepositoryCleanup](https://developers.hp.com/hp-client-management/doc/Invoke-RepositoryCleanup)

.LINK
  [Set-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Set-RepositoryNotificationConfiguration)

.LINK 
  [Clear-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Clear-RepositoryNotificationConfiguration)

.LINK 
  [Get-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Get-RepositoryNotificationConfiguration)

.LINK 
  [Show-RepositoryNotificationConfiguration](https://developers.hp.com/hp-client-management/doc/Show-RepositoryNotificationConfiguration)

.LINK
  [Remove-RepositorySyncFailureRecipient](https://developers.hp.com/hp-client-management/doc/Remove-RepositorySyncFailureRecipient)

.EXAMPLE
  Test-RepositoryNotificationConfiguration

#>
function Test-RepositoryNotificationConfiguration
{
  [CmdletBinding(HelpUri = "https://developers.hp.com/hp-client-management/doc/Test-RepositoryNotificationConfiguration")]
  param()

  Log ("test email started")
  send "Repository Failure Notification (Test only)" "No content." -html $false
  Write-Verbose ("Ok.")
}

<#
.SYNOPSIS
  Sets repository configuration values

.DESCRIPTION
  This command is used to configure different settings of the repository synchronization:

  - OnRemoteFileNotFound: Indicates the behavior for when the SoftPaq is not found on the remote site. 'Fail' stops the execution. 'LogAndContinue' logs the errors and continues the execution.
  - RepositoryReport: Indicates the format of the report generated at repository synchronization. The default format is 'CSV' and other options available are 'JSON,' 'XML,' and 'ExcelCSV.'
  - OfflineCacheMode: Indicates that all repository files are required for offline use. Repository synchronization will include platform list, advisory, and knowledge base files. The default value is 'Disable' and the other option is 'Enable.'

.PARAMETER Setting
  Specifies the setting to configure. The value must be one of the following values: 'OnRemoteFileNotFound', 'OfflineCacheMode', or 'RepositoryReport'.

.PARAMETER Value
  Specifies the new value for the OnRemoteFileNotFound setting. The value must be either: 'Fail' (default), or 'LogAndContinue'.

.PARAMETER CacheValue
  Specifies the new value for the OfflineCacheMode setting. The value must be either: 'Disable' (default), or 'Enable'.

.PARAMETER Format
  Specifies the new value for the RepositoryReport setting. The value must be one of the following: 'CSV' (default), 'JSon', 'XML', or 'ExcelCSV'.

.LINK
  [Initialize-Repository](https://developers.hp.com/hp-client-management/doc/Initialize-Repository)

.LINK
  [Get-RepositoryConfiguration](https://developers.hp.com/hp-client-management/doc/Get-RepositoryConfiguration)

.Example
  Set-RepositoryConfiguration -Setting OnRemoteFileNotFound -Value LogAndContinue

.Example
  Set-RepositoryConfiguration -Setting OfflineCacheMode -CacheValue Enable

.Example
  Set-RepositoryConfiguration -Setting RepositoryReport -Format CSV

.NOTES
  - When using HP Image Assistant and offline mode, use: Set-RepositoryConfiguration -Setting OfflineCacheMode -CacheValue Enable
  - More information on using HPIA with CMSL can be found at this [blog post](https://developers.hp.com/hp-client-management/blog/driver-injection-hp-image-assistant-and-hp-cmsl-in-memcm).
  - To create a report outside the repository, use the New-RepositoryReport command.
#>
function Set-RepositoryConfiguration
{
  [CmdletBinding(HelpUri = "https://developers.hp.com/hp-client-management/doc/Set-RepositoryConfiguration")]
  param(
    [ValidateSet('OnRemoteFileNotFound','OfflineCacheMode','RepositoryReport')]
    [Parameter(ParameterSetName = "ErrorHandler",Position = 0,Mandatory = $true)]
    [Parameter(ParameterSetName = "CacheMode",Position = 0,Mandatory = $true)]
    [Parameter(ParameterSetName = "ReportHandler",Position = 0,Mandatory = $true)]
    [string]$Setting,

    [Parameter(ParameterSetName = "ErrorHandler",Position = 1,Mandatory = $true)]
    [ErrorHandling]$Value,

    [ValidateSet('Enable','Disable')]
    [Parameter(ParameterSetName = "CacheMode",Position = 1,Mandatory = $true)]
    [string]$CacheValue,

    [ValidateSet('CSV','JSon','XML','ExcelCSV')]
    [Parameter(ParameterSetName = "ReportHandler",Position = 1,Mandatory = $true)]
    [string]$Format
  )
  $c = LoadRepository
  if (-not $c[0]) { return }
  if ($Setting -eq "OnRemoteFileNotFound") {
    if (($Value -eq "Fail") -or ($Value -eq "LogAndContinue")) {
      $c[1].settings. "${Setting}" = $Value
      WriteRepositoryFile -obj $c[1]
      Write-Verbose ("Ok.")
    }
    else {
      Write-Host -ForegroundColor Magenta "Enter valid Value for $Setting."
      Write-LogWarning "Enter valid Value for $Setting."
    }
  }
  elseif ($Setting -eq "OfflineCacheMode") {
    if ($CacheValue) {
      $c[1].settings. "${Setting}" = $CacheValue
      WriteRepositoryFile -obj $c[1]
      Write-Verbose ("Ok.")
    }
    else {
      Write-Host -ForegroundColor Magenta "Enter valid CacheValue for $Setting."
      Write-LogWarning "Enter valid CacheValue for $Setting."
    }
  }
  elseif ($Setting -eq "RepositoryReport") {
    if ($Format) {
      $c[1].settings. "${Setting}" = $Format
      WriteRepositoryFile -obj $c[1]
      Write-Verbose ("Ok.")
    }
    else {
      Write-Host -ForegroundColor Magenta "Enter valid Format for $Setting."
      Write-LogWarning "Enter valid Format for $Setting."
    }
  }
}

<#
.SYNOPSIS
    Retrieves the configuration values for a specified setting in the current repository

.DESCRIPTION
  This command retrieves various configuration options that control synchronization behavior. The settings this command can retrieve include: 

  - OnRemoteFileNotFound: Indicates the behavior for when the SoftPaq is not found on the remote site. 'Fail' stops the execution. 'LogAndContinue' logs the errors and continues the execution.
  - RepositoryReport: Indicates the format of the report generated at repository synchronization. The default format is 'CSV' and other options available are 'JSON', 'XML', and 'ExcelCSV'.
  - OfflineCacheMode: Indicates that all repository files are required for offline use. Repository synchronization will include platform list, advisory, and knowledge base files. The default value is 'Disable' and the other option is 'Enable'.

   
.PARAMETER setting
  Specifies the setting to retrieve. The value can be one of the following: 'OnRemoteFileNotFound', 'RepositoryReport', or 'OfflineCacheMode'.


.Example
  Get-RepositoryConfiguration -Setting OfflineCacheMode

.Example
  Get-RepositoryConfiguration -Setting OnRemoteFileNotFound

.Example
  Get-RepositoryConfiguration -Setting RepositoryReport

.LINK
  [Set-RepositoryConfiguration](https://developers.hp.com/hp-client-management/doc/Set-RepositoryConfiguration)

.LINK
  [Initialize-Repository](https://developers.hp.com/hp-client-management/doc/Initialize-Repository)
#>
function Get-RepositoryConfiguration
{
  [CmdletBinding(HelpUri = "https://developers.hp.com/hp-client-management/doc/Get-RepositoryConfiguration")]
  param(
    [Parameter(Position = 0,Mandatory = $true)]
    [string]
    [ValidateSet('OnRemoteFileNotFound','OfflineCacheMode','RepositoryReport')]
    $Setting
  )
  $c = LoadRepository
  if (-not $c[0]) { return }
  $c[1].settings. "${Setting}"
}


<#
.SYNOPSIS
  Creates a report from a repository directory

.DESCRIPTION
  This command creates a report from a repository directory or any directory containing CVAs (and EXEs) in one of the supported formats.

  The supported formats are:

  - XML: Returns an XML object
  - JSON: Returns a JSON document
  - CSV: Returns a CSV object
  - ExcelCSV: Returns a CSV object containing an Excel hint that defines the comma character as the delimiter. Use this format only if you plan on opening the CSV file with Excel.

  If a format is not specified, this command will return the output as PowerShell objects to the pipeline. Please note that the repository directory must contain CVAs for the command to generate a report successfully. EXEs are not required, but the EXEs will allow information like the time of download and size in bytes to be included in the report. 

.PARAMETER Format
  Specifies the output format (CSV, JSON, or XML) of the report. If not specified, this command will return the output as PowerShell objects.

.PARAMETER RepositoryPath
  Specifies a different location for the repository. By default, this command assumes the repository is the current directory.

.PARAMETER OutputFile
  Specifies a file to write the output to. You can specify a relative path or an absolute path. If a relative path is specified, the file will be written relative to the current directory and if RepositoryPath parameter is also specified, the file will still be written relative to the current directory and not relative to the value in RepositoryPath. 
  This parameter requires the -Format parameter to also be specified. 
  If specified, this command will create the file (if it does not exist) and write the output to the file instead of returning the output as a PowerShell, XML, CSV, or JSON object. 
  Please note that if the output file already exists, the contents of the file will be overwritten. 


.EXAMPLE
  New-RepositoryReport -Format JSON -RepositoryPath c:\myrepository\softpaqs -OutputFile c:\repository\today.json

.EXAMPLE
  New-RepositoryReport -Format ExcelCSV -RepositoryPath c:\myrepository\softpaqs -OutputFile c:\repository\today.csv

.NOTES
  This command currently supports scenarios where the SoftPaq executable is stored under the format sp<softpaq-number>.exe.
#>
function New-RepositoryReport
{
  [CmdletBinding(HelpUri = "https://developers.hp.com/hp-client-management/doc/New-RepositoryReport")]
  param(
    [Parameter(Position = 0,Mandatory = $false)]
    [ValidateSet('CSV','JSon','XML','ExcelCSV')]
    [string]$Format,

    [Parameter(Position = 1,Mandatory = $false)]
    [System.IO.DirectoryInfo]$RepositoryPath = '.',

    [Parameter(Position = 2,Mandatory = $false)]
    [System.IO.FileInfo]$OutputFile
  )
  if ($OutputFile -and -not $format) { throw "OutputFile parameter requires a Format specifier" }

  $cvaList = @(Get-ChildItem -Path $RepositoryPath -Filter '*.cva')

  if (-not $cvaList -or -not $cvaList.Length)
  {
    throw [System.IO.FileNotFoundException]"Directory '$(Get-Location)' does not contain CVA files."
  }

  if($cvaList.Length -eq 1){
    Write-Verbose "Processing $($cvaList.Length) CVA"
  }
  else{
    Write-Verbose "Processing $($cvaList.Length) CVAs"
  }

  $results = $cvaList | ForEach-Object {
    Write-Verbose "Processing $($_.FullName)"
    $cva = Get-HPPrivateReadINI $_.FullName

    try {
      $exe = Get-ChildItem -Path ($cva.Softpaq.SoftpaqNumber.trim() + ".exe") -ErrorAction stop
    }
    catch [System.Management.Automation.ItemNotFoundException]{
      $exe = $null
    }

    [pscustomobject]@{
      Softpaq = $cva.Softpaq.SoftpaqNumber
      Vendor = $cva.General.VendorName
      Title = $cva. "Software Title".US
      type = if ($Cva.General.Category.contains("-")) { $Cva.General.Category.substring(0,$Cva.General.Category.IndexOf('-')).trim() } else { $Cva.General.Category }
      Version = "$($cva.General.Version) Rev.$($cva.General.Revision)"
      Downloaded = if ($exe) { $exe.CreationTime } else { "" }
      Size = if ($exe) { "$($exe.Length)" } else { "" }
    }
  }
  switch ($format)
  {
    "CSV" {
      $r = $results | ConvertTo-Csv -NoTypeInformation
    }
    "ExcelCSV" {

      $r = $results | ConvertTo-Csv -NoTypeInformation
      $r = [string[]]"sep=," + $r
    }
    "JSon" {
      $r = $results | ConvertTo-Json
    }
    "XML" {
      $r = $results | ConvertTo-Xml -NoTypeInformation
    }
    default {
      return $results
    }
  }

  if ($OutputFile) {
    if ($format -eq "xml") { $r = $r.OuterXml }
    $r | Out-File -FilePath $OutputFile -Encoding utf8
  }
  else { $r }
}






# SIG # Begin signature block
# MIIoHQYJKoZIhvcNAQcCoIIoDjCCKAoCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCLWu0PSTkPMWFM
# c0B05gEUfCsg+OW0Zi9AF2uypDK+BKCCDYowggawMIIEmKADAgECAhAIrUCyYNKc
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
# KwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGf94P29
# AzNJxgRCSj4z+xQQOKeAE4SehhHxaoC2hLAtMA0GCSqGSIb3DQEBAQUABIIBgGw2
# 09K5obK8dTPFVEJ7Xbn4i/hSIJflqElHd00LPKNPOkMNgkwZJojNvNRwqLXGRqWM
# YB08iqOCLGKLU4xIy+nRNyQdtv+UaIyLlvDCPRDL5G/cqKOpWrWW9IHIkT5xYOlJ
# 3ApWuOEQzfgPf6i2QmC1PacIUApd43iGOICtAGQZGZyo9I0jHozcPShM2SOLQiPC
# dNHQPJ0Em1WOiJYOtXeDc+0lv8tBnPgQ9qfsijzAx8jVxFRLhuV5bxAnnzOZLpr4
# zHGPDftZBj92uyKuYsdtPFluQbMCdtc/VFmEsiZatl7NpAlCmcdTryBJrEusUMvl
# qDXUXCoHUpOVrM9jNxxUIXIGh3GM7Qoe3F7T38EtUIfLcYHRe2ubqHp70csR7kA8
# I071EYYGW6ZgnOvhe/pWVg10Hdo8kRdtvEONrUGvf5isPdBNLzDVDAqGzju2YA9P
# OqwWy6f9fm7kQfTJK8jCeOcv++sACUungTFToqsa3m4MJFE442uPA5UwevU2caGC
# Fz8wghc7BgorBgEEAYI3AwMBMYIXKzCCFycGCSqGSIb3DQEHAqCCFxgwghcUAgED
# MQ8wDQYJYIZIAWUDBAIBBQAwdwYLKoZIhvcNAQkQAQSgaARmMGQCAQEGCWCGSAGG
# /WwHATAxMA0GCWCGSAFlAwQCAQUABCC7aA5hNChRtpC2L5fTewohV+Xwyw39AIPV
# 87ZVXULQYwIQeHwpzsyt37Gui1YxkoSNERgPMjAyNDA4MjcxNjU1NDlaoIITCTCC
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
# SIb3DQEJEAEEMBwGCSqGSIb3DQEJBTEPFw0yNDA4MjcxNjU1NDlaMCsGCyqGSIb3
# DQEJEAIMMRwwGjAYMBYEFGbwKzLCwskPgl3OqorJxk8ZnM9AMC8GCSqGSIb3DQEJ
# BDEiBCB6wXI1EaPuxT1qzuNtfpFv70JL2YgjjM0uRYcST3HX/zA3BgsqhkiG9w0B
# CRACLzEoMCYwJDAiBCDS9uRt7XQizNHUQFdoQTZvgoraVZquMxavTRqa1Ax4KDAN
# BgkqhkiG9w0BAQEFAASCAgAsc19nhCO9BBRWRAnlIVbPsC/YbA/6o5qRsG26k123
# goBWOtRQ1ZkeD0pQVvT7fh1Hpd32z6F7hDjtfWCh0j5AAzef9V1z9dMoe1pYNeaz
# 96lLqDmls57Hf2RJB31tV2CuC6I4oD8HToEYpMTxJbP1W0ila/hQ1+bZeHw21hVj
# jKijDuyilnh05foXLYzzYRDIeWv1c+wc9Q76zv7lP651qLMohkqPg/yPXuaQtreY
# aq8kVm9iabV8Sz5sgPEAgSnZcUecKKLVmAqHHO0q6i+Z2DQaw9zwLG3FCXckaO6C
# Cup3h7l06K41SJrY/zZWr+cC5ovygRBA0+BjQ6mmXMyxLUgbU+eNqqys8PbjimJk
# 9fgt2fU2xE70CyuwEUvkvVLzFCcZXDexFjat3PDTyXwlHJUf6NOtkvNOoxqiS/XQ
# UdoDNFbZYndaT59Hg5z+zR3AUhVawV9g2cgWbCvWdzsBSctMOzCylCnHdOMowe7M
# RbbNhhNyqGDSthCMp4e66mbo/SWmzq3OP1D700B/2YYMeguLajE3r2qvdxmMkGzm
# /l+bHvHy7jvVPnCw83F32C/e58p4b/qiy1/YY9XYnQ5BON/Kp5rOgbHbL5yhdELZ
# yih64+W8rnxCDTmU7J33++JPcSF1zr2cUrriE9kA0cj+xqJhsQjA7L31p42G8mYP
# RQ==
# SIG # End signature block
