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

# For PS7, PSEdition is Core and for PS5.1, PSEdition is Desktop
if ($PSEdition -eq "Core") {
  Add-Type -Assembly $PSScriptRoot\refs\WinRT.Runtime.dll
  Add-Type -Assembly $PSScriptRoot\refs\Microsoft.Windows.SDK.NET.dll
}
else {
  [void][Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
  [void][Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications,  ContentType = WindowsRuntime]
  [void][Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]
}

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
    Creates a logo object
    .DESCRIPTION
    This command creates a toaster logo from a file image.
    .PARAMETER Image
    Specifies the URL to the image.Http images must be 200 KB or less in size. Not all URL formats are supported in all scenarios.
    .PARAMETER Crop
    Specifies how you would like the image to be cropped.
    .EXAMPLE
    PS>  $logo = New-HPPrivateToastNotificationLogo .\logo.png
    .OUTPUTS
    This command returns the object representing the logo image.
#>
function New-HPPrivateToastNotificationLogo
{
  param(
    [Parameter(Position = 0,Mandatory = $True,ValueFromPipeline = $True)]
    [System.IO.FileInfo]$Image,

    [Parameter(Position = 1,Mandatory = $False)]
    [ValidateSet('None','Default','Circle')]
    [string]$Crop
  )

  [xml]$xml = New-Object System.Xml.XmlDocument
  $child = $xml.CreateElement("image")
  $child.SetAttribute('src',$Image.FullName)
  $child.SetAttribute('placement','appLogoOverride')
  if ($Crop) { $child.SetAttribute('hint-crop',$Crop.ToLower()) }
  $child
}

<#
    .SYNOPSIS
    Creates a toast image object
    .DESCRIPTION
    This command creates a toaster image from a file image. This image may be shown in the body of a toast message.
    .PARAMETER Image
    Specifies the URL to the image. Http images must be 200 KB or less in size.  Not all URL formats are supported in all scenarios.
    .PARAMETER Position
     Specifies that toasts can display a 'fixed' image, which is a featured ToastGenericHeroImage displayed prominently within the toast banner and while inside Action Center. Image dimensions are 364x180 pixels at 100% scaling.
     Alternately, use 'inline' to display a full-width inline-image that appears when you expand the toast.

    .EXAMPLE
    PS>  $logo = New-HPPrivateToastNotificationLogo .\hero.png
    .OUTPUTS
    This function returns the object representing the image.
    .LINK
    [ToastGenericHeroImage](https://docs.microsoft.com/en-us/windows/uwp/design/shell/tiles-and-notifications/toast-schema#toastgenericheroimage)
#>
function New-HPPrivateToastNotificationImage
{
  param(
    [Parameter(Position = 0,Mandatory = $True,ValueFromPipeline = $True)]
    [string]$Image,
    [Parameter(Position = 1,Mandatory = $False)]
    [ValidateSet('Inline','Fixed')]
    [string]$Position = 'Fixed'
  )
  [xml]$xml = New-Object System.Xml.XmlDocument
  $child = $xml.CreateElement("image")
  $child.SetAttribute('src',$Image)
  #$child.SetAttribute('placement','appLogoOverride') is this needed?

  if ($Position -eq 'Fixed') {
    $child.SetAttribute('placement','hero')
  }
  else
  {
    $child.SetAttribute('placement','inline')
  }
  $child
}

<#
    .SYNOPSIS
    Specifies the toast message alert sound
    .DESCRIPTION
    This command allows defining the sound to play on toast notification.
    .PARAMETER Sound
    Specifies the sound to play
    .PARAMETER Loop
    If specified, the sound will be looped

    .EXAMPLE
    PS>  $logo = New-HPPrivateToastSoundPreference -Sound "Alarm6" -Loop
    .OUTPUTS
    This function returns the object representing the sound preference.
    .LINK
    [ToastAudio](https://docs.microsoft.com/en-us/windows/uwp/design/shell/tiles-and-notifications/toast-schema#ToastAudio)
#>
function New-HPPrivateToastSoundPreference
{
  param(
    [Parameter(Position = 1,Mandatory = $False)]
    [ValidateSet('None','Default','IM','Mail','Reminder','SMS',
      'Alarm','Alarm2','Alarm3','Alarm4','Alarm5','Alarm6','Alarm7','Alarm8','Alarm9','Alarm10',
      'Call','Call2','Call3','Call4','Call5','Call6','Call7','Call8','Call9','Call10')]
    [string]$Sound = "Default",
    [Parameter(Position = 2,Mandatory = $False)]
    [switch]$Loop
  )
  [xml]$xml = New-Object System.Xml.XmlDocument
  $child = $xml.CreateElement("audio")
  if ($Sound -eq "None") {
    $child.SetAttribute('silent',"$true".ToLower())
    Write-Verbose "Setting audio notification to Muted"
  }
  else
  {
    $soundPath = "ms-winsoundevent:Notification.$Sound"
    if ($Sound.StartsWith('Alarm') -or $Sound.StartsWith('Call'))
    {
      $soundPath = 'winsoundevent:Notification.Looping.' + $Sound
    }
    Write-Verbose "Setting audio notification to: $soundPath"
    $child.SetAttribute('src',$soundPath)
    $child.SetAttribute('loop',([string]$Loop.IsPresent).ToLower())
    Write-Verbose "Looping audio: $($Loop.IsPresent)"
  }
  $child
}

<#
    .SYNOPSIS
    Creates a toast button
    .DESCRIPTION
    Creates a toast button for the toast
    .PARAMETER Sound
    Specifies the sound to play
    .PARAMETER Image
    Specifies the button image for a graphical button
    .PARAMETER Arguments
    Specifies app-defined string of arguments that the app will later receive if the user clicks this button.
    .OUTPUTS
    This command returns the object representing the button
    .LINK
    [ToastButton](https://docs.microsoft.com/en-us/windows/uwp/design/shell/tiles-and-notifications/toast-schema#ToastButton)
#>
function New-HPPrivateToastButton
{
    [Cmdletbinding()]
    param(
        [string]$Caption,
        [string]$Image, # leave out for normal button
        [string]$Arguments,
        [ValidateSet('Background','Protocol','System')]
        [string]$ActivationType = 'background'
    )

    Write-Verbose "Creating new toast button with caption $Caption"
    if ($Image) {
        ([xml]"<action content=`"$Caption`" imageUri=`"$Image`" arguments=`"$Arguments`" activationType=`"$ActivationType`" />").DocumentElement
    } else {
        ([xml]"<action content=`"$Caption`" arguments=`"$Arguments`" activationType=`"$ActivationType`" />").DocumentElement

    }
}

<#
  .SYNOPSIS
  Create a toast action

  .DESCRIPTION
  Create a toast action for the toast

  .PARAMETER SnoozeOrDismiss
  Automatically constructs a selection box for snooze intervals, and snooze/dismiss buttons, all automatically localized, and snoozing logic is automatically handled by the system.

  .PARAMETER Image
  For a graphical button, specify the button image

  .PARAMETER Arguments
  App-defined string of arguments that the app will later receive if the user clicks this button.

  .OUTPUTS
  This function returns the object representing the button
#>
function New-HPPrivateToastActions
{
  [CmdletBinding()]
  param(
    [Parameter(ParameterSetName = 'DismissSuppress',Position = 1,Mandatory = $True)]
    [switch]$SnoozeOrDismiss,

    [Parameter(ParameterSetName = 'DismissSuppress',Position = 2,Mandatory = $True)]
    [int]$SnoozeMinutesDefault,

    [Parameter(ParameterSetName = 'DismissSuppress',Position = 3,Mandatory = $True)]
    [int[]]$SnoozeMinutesOptions,

    [Parameter(ParameterSetName = 'CustomButtons',Position = 1,Mandatory = $True)]
    [switch]$CustomButtons,

    [Parameter(ParameterSetName = 'CustomButtons',Position = 2,Mandatory = $false)]
    [System.Xml.XmlElement[]]$Buttons,

    [Parameter(ParameterSetName = 'CustomButtons',Position = 3,Mandatory = $false)]
    [switch]$NoDismiss

  )
  [xml]$xml = New-Object System.Xml.XmlDocument
  $child = $xml.CreateElement("actions")

  switch ($PSCmdlet.ParameterSetName) {
    'DismissSuppress' {
      Write-Verbose "Creating system-handled snoozable notification"

      $i = $xml.CreateElement("input")
      [void]$child.AppendChild($i)

      $i.SetAttribute('id',"snoozeTime")
      $i.SetAttribute('type','selection')
      $i.SetAttribute('defaultInput',$SnoozeMinutesDefault)

      Write-Verbose "Notification snooze default: SnoozeMinutesDefault"
      $SnoozeMinutesOptions | ForEach-Object {
        $s = $xml.CreateElement("selection")
        $s.SetAttribute('id',"$_")
        $s.SetAttribute('content',"$_ minute")
        [void]$i.AppendChild($s)
      }

      $action = $xml.CreateElement("action")
      $action.SetAttribute('activationType','system')
      $action.SetAttribute('arguments','snooze')
      $action.SetAttribute('hint-inputId','snoozeTime')
      $action.SetAttribute('content','Snooze')
      [void]$child.AppendChild($action)

      Write-Verbose "Creating custom buttons toast"
      if ($Buttons) {
        $Buttons | ForEach-Object {
          $node = $xml.ImportNode($_,$true)
          [void]$child.AppendChild($node)
        }
      }

      $action = $xml.CreateElement("action")
      $action.SetAttribute('activationType','system')
      $action.SetAttribute('arguments','dismiss')
      $action.SetAttribute('content','Dismiss')
      [void]$child.AppendChild($action)
    }

    'CustomButtons' { # customized buttons
      Write-Verbose "Creating custom buttons toast"

      if($Buttons) {
        $Buttons | ForEach-Object {
          $node = $xml.ImportNode($_,$true)
          [void]$child.AppendChild($node)
        }
      }

      if (-not $NoDismiss.IsPresent) {
        $action = $xml.CreateElement("action")
        $action.SetAttribute('activationType','system')
        $action.SetAttribute('arguments','dismiss')
        $action.SetAttribute('content','Dismiss')
        [void]$child.AppendChild($action)
      }
    }

    default {

    }
  }

  $child
}

<#
    .SYNOPSIS
    Shows a toast message
    .DESCRIPTION
    This command shows a toast message, and optionally registers a response handler.
    .PARAMETER Message
    Specifies the message to show
    .PARAMETER Title
    Specifies title of the message to show
    .PARAMETER Logo
    Specifies a logo object created with New-HPPrivateToastNotificationLogo
    .PARAMETER Image
    Specifies a logo object created with New-HPPrivateToastNotificationImage
    .PARAMETER Expiration
    Specifies a timeout in minutes for the toast to remove itself
    .PARAMETER Tag
    Specifies a tag value for the toast. Please note that if a toast with the same tag already exists, it will be replaced by this one.
    .PARAMETER Group
    Specifies a group value for the toast
    .PARAMETER Attribution
    Specifies toast owner
    .PARAMETER Sound
    Specifies a sound notification preference created with New-HPPrivateToastSoundPreference
    .PARAMETER Actions
    .PARAMETER Persist
#>
function New-HPPrivateToastNotification
{
  [CmdletBinding()]
  param(
    [Parameter(ParameterSetName = 'TextOnly',Position = 0,Mandatory = $False,ValueFromPipeline = $True)]
    [string]$Message,

    [Parameter(Position = 1,Mandatory = $False)]
    [string]$Title,

    [Parameter(Position = 3,Mandatory = $False)]
    [System.Xml.XmlElement]$Logo,

    [Parameter(Position = 4,Mandatory = $False)]
    [int]$Expiration,

    [Parameter(Position = 5,Mandatory = $False)]
    [string]$Tag,

    [Parameter(Position = 6,Mandatory = $False)]
    [string]$Group = "hp-cmsl",

    [Parameter(Position = 8,Mandatory = $False)]
    [System.Xml.XmlElement]$Sound,

    # Apparently can't do URLs with non-uwp
    [Parameter(Position = 11,Mandatory = $False)]
    [System.Xml.XmlElement]$Image,

    [Parameter(Position = 13,Mandatory = $False)]
    [System.Xml.XmlElement]$Actions,

    [Parameter(Position = 14,Mandatory = $False)]
    [switch]$Persist,

    [Parameter(Position = 15 , Mandatory = $False)]
    [string]$Signature,

    [Parameter(Position = 16,Mandatory = $False)]
    [System.IO.FileInfo]$Xml
  )
  # if $Xml is given, load the xml instead of manually creating it
  if ($Xml) {
    Write-Verbose "Loading XML from $Xml"
    try {
      [xml]$xml = Get-Content $Xml
    } catch {
      Write-Error "Failed to load schema XML from $Xml"
      return
    }
  } else {

    # In order for signature text to be smaller, we have to add placement="attribution" to the text node. 
    # When using placement="attribution", Signature text will always be displayed at the bottom of the toast notification, 
    # along with the app's identity or the notification's timestamp if we were to customize the notification to provide these as well. 
    # On older versions of Windows that don't support attribution text, the text will simply be displayed as another text element 
    # (assuming we don't already have the maximum of three text elements, 
    # but we currently only have Invoke-HPNotification showing up to 3 text elements with the 3rd for $Signature being smallest)
    [xml]$xml = '<toast><visual><binding template="ToastGeneric"><text></text><text></text><text placement="attribution"></text></binding></visual></toast>'

    $binding = $xml.GetElementsByTagName("toast")
    if ($Sound) {
      $node = $xml.ImportNode($Sound,$true)
      [void]$binding.AppendChild($node)
    }

    if ($Persist.IsPresent)
    {
      $binding.SetAttribute('scenario','reminder')
    }

    if ($Actions) {
      $node = $xml.ImportNode($Actions,$true)
      [void]$binding.AppendChild($node)
    }

    $binding = $xml.GetElementsByTagName("binding")
    if ($Logo) {
      $node = $xml.ImportNode($Logo,$true)
      [void]$binding.AppendChild($node)
    }

    if ($Image) {
      $node = $xml.ImportNode($Image,$true)
      [void]$binding.AppendChild($node)
    }

    $binding = $xml.GetElementsByTagName("text")
    if ($Title) {
      [void]$binding[0].AppendChild($xml.CreateTextNode($Title.trim()))
    }

    [void]$binding[1].AppendChild($xml.CreateTextNode($Message.trim()))

    if ($Signature){
      [void]$binding[2].AppendChild($xml.CreateTextNode($Signature.trim()))
    }
  }

  Write-Verbose "Submitting toast with XML: $($xml.OuterXml)"
  $toast = [Windows.Data.Xml.Dom.XmlDocument]::new()
  $toast.LoadXml($xml.OuterXml)

  $toast = [Windows.UI.Notifications.ToastNotification]::new($toast)

  # if you specify a non-unique tag, it will replace the previous toast with the same non-unique tag
  if($Tag) {
    $toast.Tag = $Tag
  }

  $toast.Group = $Group

  if ($Expiration) {
    $toast.ExpirationTime = [DateTimeOffset]::Now.AddMinutes($Expiration)
  }

  return $toast
}

function Show-ToastNotification {
  [CmdletBinding()]
  param(
    [Parameter(Position = 0,Mandatory = $False,ValueFromPipeline = $true)]
    $Toast,

    [Parameter(Position = 1,Mandatory = $False)]
    [string]$Attribution = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
  )

  $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($Attribution)
  $notifier.Show($toast)
}

function Register-HPPrivateScriptProtocol {
  [CmdletBinding()]
  param(
    [string]$ScriptPath,
    [string]$Name
  )

  try {
    New-Item "HKCU:\Software\Classes\$($Name)\shell\open\command" -Force -ErrorAction SilentlyContinue | Out-Null
    New-ItemProperty -LiteralPath "HKCU:\Software\Classes\$($Name)" -Name 'URL Protocol' -Value '' -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null
    New-ItemProperty -LiteralPath "HKCU:\Software\Classes\$($Name)" -Name '(default)' -Value "url:$($Name)" -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null
    New-ItemProperty -LiteralPath "HKCU:\Software\Classes\$($Name)" -Name 'EditFlags' -Value 2162688 -PropertyType Dword -Force -ErrorAction SilentlyContinue | Out-Null
    New-ItemProperty -LiteralPath "HKCU:\Software\Classes\$($Name)\shell\open\command" -Name '(default)' -Value $ScriptPath -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null
  }
  catch {
    Write-Host $_.Exception.Message
  }
}


<#
.SYNOPSIS
  This is a private command for internal use only

.DESCRIPTION
  This is a private command for internal use only

.EXAMPLE

.NOTES
  - This is a private command for internal use only
#>
function Invoke-HPPrivateRebootNotificationAsUser {
  [CmdletBinding()]
  param(
    [Parameter(Position = 0,Mandatory = $false)]
    [string]$Title = "A System Reboot is Required",

    [Parameter(Position = 1,Mandatory = $false)]
    [string]$Message = "Please reboot now to keep your device compliant with the security policies.",

    [Parameter(Position = 2,Mandatory = $false)]
    [System.IO.FileInfo]$LogoImage,

    [Parameter(Position = 4,Mandatory = $false)]
    [int]$Expiration = 0,

    [Parameter(Position = 4,Mandatory = $False)]
    [string]$Attribution
  )

  # Use System Root instead of hardcoded path to C:\Windows
  Register-HPPrivateScriptProtocol -ScriptPath "$env:SystemRoot\System32\shutdown.exe -r -t 0 -f" -Name "rebootnow"

  $rebootButton = New-HPPrivateToastButton -Caption "Reboot now" -Image $null -Arguments "rebootnow:" -ActivationType "Protocol"

  $params = @{
    Message = $Message
    Title = $Title
    Expiration = $Expiration
    Actions = New-HPPrivateToastActions -CustomButtons -Buttons $rebootButton
    Sound = New-HPPrivateToastSoundPreference -Sound IM
  }

  if ($LogoImage) {
    $params.Logo = New-HPPrivateToastNotificationLogo -Image $LogoImage -Crop Circle
  }

  $toast = New-HPPrivateToastNotification @params -Persist

  if ($toast) {
    if ([string]::IsNullOrEmpty($Attribution)) {
      Show-ToastNotification -Toast $toast
    }
    else {
      Show-ToastNotification -Toast $toast -Attribution $Attribution
    }
  }

  return
}

<#
.SYNOPSIS
  This is a private command for internal use only

.DESCRIPTION
  This is a private command for internal use only

.EXAMPLE

.NOTES
  - This is a private command for internal use only
#>
function Invoke-HPPrivateNotificationAsUser {
  [CmdletBinding()]
  param(
    [Parameter(Position = 0,Mandatory = $false)]
    [string]$Title,

    [Parameter(Position = 1,Mandatory = $false)]
    [string]$Message,

    [Parameter(Position = 2,Mandatory = $false)]
    [System.IO.FileInfo]$LogoImage,

    [Parameter(Position = 4,Mandatory = $false)]
    [int]$Expiration = 0,

    [Parameter(Position = 4,Mandatory = $False)]
    [string]$Attribution,

    [Parameter(Position = 5,Mandatory = $false)]
    [string]$NoDismiss = "false", # environment variables can only be strings, so Dismiss parameter is a string

    [Parameter(Position = 6,Mandatory = $false)]
    [string]$Signature,

    [Parameter(Position = 7,Mandatory = $false)]
    [System.IO.FileInfo]$Xml,

    [Parameter(Position = 8,Mandatory = $false)]
    [System.IO.FileInfo]$Actions
  )

  if ($Xml){
    if($Actions){
      # parse the file of Actions to get the actions to register 
      try {
       $listOfActions = Get-Content $Actions | ConvertFrom-Json
      }
      catch {
       Write-Error "Failed to parse the file of actions: $($_.Exception.Message). Will not proceed with invoking notification."
       return
      }

      # register every action in list of actions 
      foreach ($action in $listOfActions) {
       Register-HPPrivateScriptProtocol -ScriptPath $action.cmd -Name $action.id
      }

      Write-Verbose "Done registering actions"
    }
    
    $toast = New-HPPrivateToastNotification -Expiration $Expiration -Xml $Xml -Persist

   if ($toast) {
     if ([string]::IsNullOrEmpty($Attribution)) {
       Show-ToastNotification -Toast $toast
     }
     else {
       Show-ToastNotification -Toast $toast -Attribution $Attribution
     }
   }
  }
  else{
    $params = @{
      Message = $Message
      Title = $Title
      Expiration = $Expiration
      Signature = $Signature
      Sound = New-HPPrivateToastSoundPreference -Sound IM
    }
  
    # environment variables can only be strings, so Dismiss parameter is a string
    if ($NoDismiss -eq "false") {
      $params.Actions = New-HPPrivateToastActions -CustomButtons
    }
    else {
      $params.Actions = New-HPPrivateToastActions -CustomButtons -NoDismiss
    }
  
    if ($LogoImage) {
      $params.Logo = New-HPPrivateToastNotificationLogo -Image $LogoImage -Crop Circle
    }
  
    $toast = New-HPPrivateToastNotification @params -Persist
  
    if ([string]::IsNullOrEmpty($Attribution)) {
      Show-ToastNotification -Toast $toast
    }
    else {
      Show-ToastNotification -Toast $toast -Attribution $Attribution
    }
  }

  return 
}

<#
.SYNOPSIS
  Register-NotificationApplication

.DESCRIPTION
  This function registers toast notification applications

.PARAMETER Id
  Specifies the application id

.PARAMETER DisplayName
  Specifies the application name to display on the toast notification

.EXAMPLE
  Register-NotificationApplication -Id 'hp.cmsl.12345' -DisplayName 'HP CMSL'
#>
function Register-NotificationApplication {
  [CmdletBinding()]
  param(
      [Parameter(Mandatory=$true)]
      [string]$Id,

      [Parameter(Mandatory=$true)]
      [string]$DisplayName,

      [Parameter(Mandatory=$false)]
      [System.IO.FileInfo]$IconPath
  )
  if (-not (Test-IsElevatedAdmin)) {
    throw [System.Security.AccessControl.PrivilegeNotHeldException]"elevated administrator"
  }

  Write-Verbose "Registering notification application with id: $Id and display name: $DisplayName and icon path: $IconPath"

  $drive = Get-PSDrive -Name HKCR -ErrorAction SilentlyContinue
  if (-not $drive) {
    $drive = New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT -Scope Script
  }
  $appRegPath = Join-Path -Path "$($drive):" -ChildPath 'AppUserModelId'
  $regPath = Join-Path -Path $appRegPath -ChildPath $Id
  if (-not (Test-Path $regPath))
  {
    New-Item -Path $appRegPath -Name $Id -Force | Out-Null
  }
  $currentDisplayName = Get-ItemProperty -Path $regPath -Name DisplayName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty DisplayName -ErrorAction SilentlyContinue
  if ($currentDisplayName -ne $DisplayName) {
    New-ItemProperty -Path $regPath -Name DisplayName -Value $DisplayName -PropertyType String -Force | Out-Null
  }

  New-ItemProperty -Path $regPath -Name IconUri -Value $IconPath -PropertyType ExpandString -Force | Out-Null	
  New-ItemProperty -Path $regPath -Name IconBackgroundColor -Value 0 -PropertyType ExpandString -Force | Out-Null
  Remove-PSDrive -Name HKCR -Force

  Write-Verbose "Registered toast notification application: $DisplayName"
}

<#
.SYNOPSIS
  Unregister-NotificationApplication

.DESCRIPTION
  This function unregisters toast notification applications. Do not unregister the application if you want to snooze the notification.

.PARAMETER Id
  Specifies the application ID to unregister 

.EXAMPLE
  Unregister-NotificationApplication -Id 'hp.cmsl.12345'
#>
function Unregister-NotificationApplication {
  [CmdletBinding()]
  param(
      [Parameter(Mandatory=$true)]
      $Id
  )
  if (-not (Test-IsElevatedAdmin)) {
    throw [System.Security.AccessControl.PrivilegeNotHeldException]"elevated administrator"
  }

  $drive = Get-PSDrive -Name HKCR -ErrorAction SilentlyContinue
  if (-not $drive) {
    $drive = New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT -Scope Script
  }
  $appRegPath = Join-Path -Path "$($drive):" -ChildPath 'AppUserModelId'
  $regPath = Join-Path -Path $appRegPath -ChildPath $Id
  if (Test-Path $regPath) {
    Remove-Item -Path $regPath
  }
  else {
    Write-Verbose "Application not found at $regPath"
  }
  Remove-PSDrive -Name HKCR -Force

  Write-Verbose "Unregistered toast notification application: $Id"
}

<#
.SYNOPSIS
  Invoke-HPRebootNotification

.DESCRIPTION
  This command shows a toast message asking the user to reboot the system. 

.PARAMETER Message
  Specifies the message to show

.PARAMETER Title
  Specifies the title of the message to show

.PARAMETER LogoImage
  Specifies the image file path to be displayed

.PARAMETER Expiration
  Specifies the timeout in minutes for the toast to remove itself. If not specified, the toast remains until dismissed.

.PARAMETER TitleBarHeader
  Specifies the text of the toast notification in the title bar. If not specified, the text will default to "HP System Update". 

.PARAMETER TitleBarIcon
  Specifies the icon of the toast notification in the title bar. If not specified, the icon will default to the HP logo. Please note that the color of the icon might be inverted depending on the background color of the title bar.


.EXAMPLE
  Invoke-HPRebootNotification -Title "My title" -Message "My message"
#>
function Invoke-HPRebootNotification {
  [CmdletBinding(HelpUri = "https://developers.hp.com/hp-client-management/doc/Invoke-RebootNotification")]
  [Alias("Invoke-RebootNotification")] # we can deprecate Invoke-RebootNotification later 
  param(
    [Parameter(Position = 0,Mandatory = $False)]
    [string]$Title = "A System Reboot Is Required",

    [Parameter(Position = 1,Mandatory = $False)]
    [string]$Message = "Please reboot now to keep your device compliant with organizational policies.",

    [Parameter(Position = 2,Mandatory = $false)]
    [System.IO.FileInfo]$LogoImage,

    [Parameter(Position = 3,Mandatory = $false)]
    [int]$Expiration = 0,

    [Parameter(Position = 4,Mandatory = $false)]
    [string]$TitleBarHeader = "HP System Update", # we don't want to display "Windows PowerShell" in the title bar

    [Parameter(Position = 5,Mandatory = $false)]
    [System.IO.FileInfo]$TitleBarIcon = (Join-Path -Path $PSScriptRoot -ChildPath 'assets\hp_black_logo.png') # default to HP logo 
  )

  # Create a unique Id to distinguish this notification application from others using "hp.cmsl" and the current time
  $Id = "hp.cmsl.$([DateTime]::Now.Ticks)"

  # Convert the relative path for TitleBarIcon into absolute path
  $TitleBarIcon = (Get-Item -Path $TitleBarIcon).FullName

  # An app registration is needed to set the issuer name and icon in the title bar 
  Register-NotificationApplication -Id $Id -DisplayName $TitleBarHeader -IconPath $TitleBarIcon

  # When using system privileges, the block executes in a different context, 
  # so the relative path for LogoImage must be converted to an absolute path.
  # On another note, System.IO.FileInfo.FullName property isn't updated when you change your working directory in PowerShell, 
  # so in the case for user privileges, 
  # using Get-Item here to avoid getting wrong absolute path later 
  # when using System.IO.FileInfo.FullName property in New-HPPrivateToastNotificationLogo. 
  if ($LogoImage) {
    $LogoImage = (Get-Item -Path $LogoImage).FullName
  }

  $privs = whoami /priv /fo csv | ConvertFrom-Csv | Where-Object { $_. 'Privilege Name' -eq 'SeDelegateSessionUserImpersonatePrivilege' }
  if ($privs.State -eq "Disabled") {
    Write-Verbose "Running with user privileges"
    Invoke-HPPrivateRebootNotificationAsUser -Title $Title -Message $Message -LogoImage $LogoImage -Expiration $Expiration -Attribution $Id
  }
  else {
    Write-Verbose "Running with system privileges"
    
    try {
      $psPath = (Get-Process -Id $pid).Path
      # Passing the parameters as environment variable because the following block executes in a different context
      [System.Environment]::SetEnvironmentVariable('HPRebootTitle',$Title,[System.EnvironmentVariableTarget]::Machine)
      [System.Environment]::SetEnvironmentVariable('HPRebootMessage',$Message,[System.EnvironmentVariableTarget]::Machine)
      [System.Environment]::SetEnvironmentVariable('HPRebootAttribution',$Id,[System.EnvironmentVariableTarget]::Machine)

      if ($LogoImage) {
        [System.Environment]::SetEnvironmentVariable('HPRebootLogoImage',$LogoImage,[System.EnvironmentVariableTarget]::Machine)
      }
      if ($Expiration) {
        [System.Environment]::SetEnvironmentVariable('HPRebootExpiration',$Expiration,[System.EnvironmentVariableTarget]::Machine)
      }
   
      [scriptblock]$scriptBlock = {
        $path = $pwd.Path
        Import-Module -Force $path\HP.Notifications.psd1
        $params = @{
          Title = $env:HPRebootTitle
          Message = $env:HPRebootMessage
          Attribution = $env:HPRebootAttribution
        }

        if ($env:HPRebootLogoImage) {
          $params.LogoImage = $env:HPRebootLogoImage
        }
       
        if ($env:HPRebootExpiration) {
          $params.Expiration = $env:HPRebootExpiration
        }
      
        Invoke-HPPrivateRebootNotificationAsUser @params
      }

      $encodedCommand = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($scriptBlock))
      $psCommand = "-ExecutionPolicy Bypass -Window Normal -EncodedCommand $($encodedCommand)"
      [ProcessExtensions]::StartProcessAsCurrentUser($psPath,"`"$psPath`" $psCommand",$PSScriptRoot)
      [System.Environment]::SetEnvironmentVariable('HPRebootTitle',$null,[System.EnvironmentVariableTarget]::Machine)
      [System.Environment]::SetEnvironmentVariable('HPRebootMessage',$null,[System.EnvironmentVariableTarget]::Machine)
      [System.Environment]::SetEnvironmentVariable('HPRebootAttribution',$null,[System.EnvironmentVariableTarget]::Machine)

      if ($LogoImage) {
        [System.Environment]::SetEnvironmentVariable('HPRebootLogoImage',$null,[System.EnvironmentVariableTarget]::Machine)
      }
      if ($Expiration) {
        [System.Environment]::SetEnvironmentVariable('HPRebootExpiration',$null,[System.EnvironmentVariableTarget]::Machine)
      }
   
    }
    catch {
      Write-Error -Message "Could not execute as currently logged on user: $($_.Exception.Message)" -Exception $_.Exception
    }
  }

  # add a delay before unregistering the app because if you unregister the app right away, toast notification won't pop up 
  Start-Sleep -Seconds 5
  Unregister-NotificationApplication -Id $Id

  return
}


<#
.SYNOPSIS
  Triggers a toast notification from XML 

.DESCRIPTION
  This command triggers a toast notification from XML. Similar to the Invoke-HPNotification command, this command triggers toast notifications, but this command is more flexible and allows for more customization.

.PARAMETER Xml
  Specifies the schema XML content of the toast notification. Please specify either Xml or XmlPath, but not both.

.PARAMETER XmlPath
  Specifies the file path to the schema XML content of the toast notification. Please specify either Xml or XmlPath, but not both.

.PARAMETER ActionsJson
  Specifies the actions that should be map the button id(s) (if any specified in XML) to the command(s) to call upon clicking the corresponding button. You can specify either ActionsJson or ActionsJsonPath, but not both.

  Please note that button actions are registered in HKEY_CURRENT_USER in the registry. Button actions will persist until the user logs off. 

  Example to reboot the system upon clicking the button:
  [
   {
      "id":"rebootnow",
      "cmd":"C:\\Windows\\System32\\shutdown.exe -r -t 0 -f"
   }
  ]

.PARAMETER ActionsJsonPath
  Specifies the file path to the actions that should be map the button id(s) (if any specified in XML) to the command(s) to call upon clicking the corresponding button. You can specify either ActionsJson or ActionsJsonPath, but not both.
  
  Please note that button actions are registered in HKEY_CURRENT_USER in the registry. Button actions will persist until the user logs off. 

.PARAMETER Expiration
  Specifies the life of the toast notification in minutes whether toast notification is on the screen or in the Action Center. If not specified, the invoked toast notification remains on screen until dismissed.

.PARAMETER TitleBarHeader
  Specifies the text of the toast notification in the title bar. If not specified, the text will default to "HP System Notification". 

.PARAMETER TitleBarIcon
  Specifies the icon of the toast notification in the title bar. If not specified, the icon will default to the HP logo. Please note that the color of the icon might be inverted depending on the background color of the title bar.


.EXAMPLE
  Invoke-HPNotificationFromXML -XmlPath 'C:\path\to\schema.xml' -ActionsJsonPath 'C:\path\to\actions.json'

.EXAMPLE
  Invoke-HPNotificationFromXML -XmlPath 'C:\path\to\schema.xml' -ActionsJson '[
   {
      "id":"rebootnow",
      "cmd":"C:\\Windows\\System32\\shutdown.exe -r -t 0 -f"
   }
  ]'

.EXAMPLE
  Invoke-HPNotificationFromXML -XmlPath 'C:\path\to\schema.xml' 

#>
function Invoke-HPNotificationFromXML {
  [CmdletBinding(HelpUri = "https://developers.hp.com/hp-client-management/doc/Invoke-HPNotificationFromXML")]
  param(
    [Parameter(ParameterSetName = 'XmlAJ',Mandatory = $false)]
    [Parameter(ParameterSetName = 'XmlAJP',Mandatory = $false)]
    [Parameter(ParameterSetName = 'XmlPathAJ',Mandatory = $false)]
    [Parameter(ParameterSetName = 'XmlPathAJP',Mandatory = $false)]
    [int]$Expiration = 0,

    [Parameter(ParameterSetName = 'XmlAJ',Mandatory = $false)]
    [Parameter(ParameterSetName = 'XmlAJP',Mandatory = $false)]
    [Parameter(ParameterSetName = 'XmlPathAJ',Mandatory = $false)]
    [Parameter(ParameterSetName = 'XmlPathAJP',Mandatory = $false)]
    [string]$TitleBarHeader = "HP System Notification", # we don't want to display "Windows PowerShell" in the title bar

    [Parameter(ParameterSetName = 'XmlAJ',Mandatory = $false)]
    [Parameter(ParameterSetName = 'XmlAJP',Mandatory = $false)]
    [Parameter(ParameterSetName = 'XmlPathAJ',Mandatory = $false)]
    [Parameter(ParameterSetName = 'XmlPathAJP',Mandatory = $false)]
    [System.IO.FileInfo]$TitleBarIcon = (Join-Path -Path $PSScriptRoot -ChildPath 'assets\hp_black_logo.png'), # default to HP logo
   
    [Parameter(ParameterSetName = 'XmlAJ',Mandatory = $true)]
    [Parameter(ParameterSetName = 'XmlAJP', Mandatory = $true)]
    [string]$Xml, # both $Xml and $XmlPath cannot be specified

    [Parameter(ParameterSetName = 'XmlPathAJ', Mandatory = $true)]
    [Parameter(ParameterSetName = 'XmlPathAJP', Mandatory = $true)]
    [System.IO.FileInfo]$XmlPath, # both $Xml and $XmlPath cannot be specified

    [Parameter(ParameterSetName = 'XmlAJ',Mandatory = $false)]
    [Parameter(ParameterSetName = 'XmlPathAJ',Mandatory = $false)]
    [string]$ActionsJson, # list of actions that should align with the buttons in the schema Xml file. If no buttons, this field is not needed

    # both $ActionsJson and $ActionsJsonPath cannot be specified, so making one mandatory to resolve ambiguity
    [Parameter(ParameterSetName = 'XmlAJP',Mandatory = $true)] 
    [Parameter(ParameterSetName = 'XmlPathAJP',Mandatory = $true)]
    [System.IO.FileInfo]$ActionsJsonPath 
    )

  # if Xml, save the contents to a file and set file path to $XmlPath
  if ($Xml) {
    # create a unique file name for the schema XML file to avoid conflicts
    $XmlPath = Join-Path -Path $PSScriptRoot -ChildPath "HPNotificationSchema$([DateTime]::Now.Ticks).xml"
    $Xml | Out-File -FilePath $XmlPath -Force
    Write-Verbose "Created schema XML file at $XmlPath"
  }

  # if ActionsJson, save the contents to a file and set file path to $ActionsJsonPath
  if ($ActionsJson) {
    # create a unique file name for the actions JSON file to avoid conflicts
    $ActionsJsonPath = Join-Path -Path $PSScriptRoot -ChildPath "HPNotificationActions$([DateTime]::Now.Ticks).json"
    $ActionsJson | Out-File -FilePath $ActionsJsonPath -Force
    Write-Verbose "Created actions JSON file at $ActionsJsonPath"
  }

  # Create a unique Id to distinguish this notification application from others using "hp.cmsl" and the current time
  $Id = "hp.cmsl.$([DateTime]::Now.Ticks)"

  # Convert the relative path for TitleBarIcon into absolute path
  $TitleBarIcon = (Get-Item -Path $TitleBarIcon).FullName

  # An app registration is needed to set the issuer name and icon in the title bar 
  Register-NotificationApplication -Id $Id -DisplayName $TitleBarHeader -IconPath $TitleBarIcon

  $privs = whoami /priv /fo csv | ConvertFrom-Csv | Where-Object { $_. 'Privilege Name' -eq 'SeDelegateSessionUserImpersonatePrivilege' }
  if ($privs.State -eq "Disabled") {
    Write-Verbose "Running with user privileges"
    Invoke-HPPrivateNotificationAsUser -Xml $XmlPath -Actions $ActionsJsonPath -Expiration $Expiration -Attribution $Id 
  }
  else {
    Write-Verbose "Running with system privileges"

    # XmlPath and ActionsJsonPath do not work with system privileges if a relative file path is passed in 
    # because the following block executes in a different context
    # If a relative path is passed in, convert the relative path into absolute path
    if ($XmlPath) {
      $XmlPath = (Get-Item -Path $XmlPath).FullName
    }

    if ($ActionsJsonPath) {
      $ActionsJsonPath = (Get-Item -Path $ActionsJsonPath).FullName
    }

    try {
      $psPath = (Get-Process -Id $pid).Path

      # Passing the parameters as environment variable because the following block executes in a different context
      [System.Environment]::SetEnvironmentVariable('HPNotificationFromXmlAttribution',$Id,[System.EnvironmentVariableTarget]::Machine)
      [System.Environment]::SetEnvironmentVariable('HPNotificationFromXmlXml',$XmlPath,[System.EnvironmentVariableTarget]::Machine)
     
      if($ActionsJsonPath){
        [System.Environment]::SetEnvironmentVariable('HPNotificationFromXmlActions',$ActionsJsonPath,[System.EnvironmentVariableTarget]::Machine)
      }

      if ($Expiration) {
        [System.Environment]::SetEnvironmentVariable('HPNotificationFromXmlExpiration',$Expiration,[System.EnvironmentVariableTarget]::Machine)
      }

      [scriptblock]$scriptBlock = {
        $path = $pwd.Path
        Import-Module -Force $path\HP.Notifications.psd1
        $params = @{
          Xml = $env:HPNotificationFromXmlXml
          Actions = $env:HPNotificationFromXmlActions
          Attribution = $env:HPNotificationFromXmlAttribution
        }

        if ($env:HPNotificationFromXmlExpiration) {
          $params.Expiration = $env:HPNotificationFromXmlExpiration
        }

        Invoke-HPPrivateNotificationAsUser @params
      }

      $encodedCommand = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($scriptBlock))
      $psCommand = "-ExecutionPolicy Bypass -Window Normal -EncodedCommand $($encodedCommand)"
      [ProcessExtensions]::StartProcessAsCurrentUser($psPath,"`"$psPath`" $psCommand",$PSScriptRoot)

      [System.Environment]::SetEnvironmentVariable('HPNotificationFromXmlAttribution',$null,[System.EnvironmentVariableTarget]::Machine)
      [System.Environment]::SetEnvironmentVariable('HPNotificationFromXmlXml',$null,[System.EnvironmentVariableTarget]::Machine)

      if($ActionsJsonPath){
        [System.Environment]::SetEnvironmentVariable('HPNotificationFromXmlActions',$null,[System.EnvironmentVariableTarget]::Machine)
      }
      if ($Expiration) {
        [System.Environment]::SetEnvironmentVariable('HPNotificationFromXmlExpiration',$null,[System.EnvironmentVariableTarget]::Machine)
      }
    }
    catch {
      Write-Error -Message "Could not execute as currently logged on user: $($_.Exception.Message)" -Exception $_.Exception
    }
  }

  # if temporary XML file was created, remove it
  if($Xml) {
    Remove-Item -Path $XmlPath -Force
    Write-Verbose "Removed temporary schema XML file at $XmlPath"
  }

  # if temporary Actions JSON file was created, remove it
  if($ActionsJson) {
    Remove-Item -Path $ActionsJsonPath -Force
    Write-Verbose "Removed temporary actions JSON file at $ActionsJsonPath"
  }

  # do not unregister the app because we want to allow the user to snooze the notification 
  return
}

<#
.SYNOPSIS
  Triggers a toast notification

.DESCRIPTION
  This command triggers a toast notification.

.PARAMETER Message
  Specifies the message to display. This parameter is mandatory. Please note, an empty string is not allowed.

.PARAMETER Title
  Specifies the title to display. This parameter is mandatory. Please note, an empty string is not allowed. 

.PARAMETER LogoImage
  Specifies the image file path to be displayed

.PARAMETER Expiration
  Specifies the life of the toast notification in minutes whether toast notification is on the screen or in the Action Center. If not specified, the invoked toast notification remains on screen until dismissed.

.PARAMETER TitleBarHeader
  Specifies the text of the toast notification in the title bar. If not specified, the text will default to "HP System Notification". 

.PARAMETER TitleBarIcon
  Specifies the icon of the toast notification in the title bar. If not specified, the icon will default to the HP logo. Please note that the color of the icon might be inverted depending on the background color of the title bar.

.PARAMETER Signature
  Specifies the text to display below the message at the bottom of the toast notification in a smaller font. Please note that on older versions of Windows that don't support attribution text, the signature will just be displayed as another text element in the same font as the message. 

.PARAMETER Dismiss
  If set to true or not specified, the toast notification will show a Dismiss button to dismiss the notification. If set to false, the toast notification will not show a Dismiss button and will disappear from the screen and go to the Action Center after 5-7 seconds of invocation. Please note that dismissing the notification overrides any specified Expiration time as the notification will not go to the Action Center once dismissed.


.EXAMPLE
  Invoke-HPNotification -Title "My title" -Message "My message" -Dismiss $false 

.EXAMPLE
  Invoke-HPNotificataion -Title "My title" -Message "My message" -Signature "Foo Bar" -Expiration 5
#>
function Invoke-HPNotification {
  [CmdletBinding(HelpUri = "https://developers.hp.com/hp-client-management/doc/Invoke-HPNotification")]
  param(
    [Parameter(Position = 0,Mandatory = $true)]
    [string]$Title,

    [Parameter(Position = 1,Mandatory = $true)]
    [string]$Message,

    [Parameter(Position = 2,Mandatory = $false)]
    [System.IO.FileInfo]$LogoImage,

    [Parameter(Position = 3,Mandatory = $false)]
    [int]$Expiration = 0,

    [Parameter(Position = 4,Mandatory = $false)]
    [string]$TitleBarHeader = "HP System Notification", # we don't want to display "Windows PowerShell" in the title bar

    [Parameter(Position = 5,Mandatory = $false)]
    [System.IO.FileInfo]$TitleBarIcon = (Join-Path -Path $PSScriptRoot -ChildPath 'assets\hp_black_logo.png'), # default to HP logo

    [Parameter(Position = 6,Mandatory = $false)]
    [string]$Signature, # text in smaller font under Title and Message at the bottom of the toast notification 
    
    [Parameter(Position = 7,Mandatory = $false)]
    [bool]$Dismiss = $true # if not specified, default to showing the Dismiss button
  )

  # Create a unique Id to distinguish this notification application from others using "hp.cmsl" and the current time
  $Id = "hp.cmsl.$([DateTime]::Now.Ticks)"

  # Convert the relative path for TitleBarIcon into absolute path
  $TitleBarIcon = (Get-Item -Path $TitleBarIcon).FullName
  
  # An app registration is needed to set the issuer name and icon in the title bar 
  Register-NotificationApplication -Id $Id -DisplayName $TitleBarHeader -IconPath $TitleBarIcon

  # When using system privileges, the block executes in a different context, 
  # so the relative path for LogoImage must be converted to an absolute path.
  # On another note, System.IO.FileInfo.FullName property isn't updated when you change your working directory in PowerShell, 
  # so in the case for user privileges, 
  # using Get-Item here to avoid getting wrong absolute path later 
  # when using System.IO.FileInfo.FullName property in New-HPPrivateToastNotificationLogo. 
  if ($LogoImage) {
    $LogoImage = (Get-Item -Path $LogoImage).FullName
  }

  $privs = whoami /priv /fo csv | ConvertFrom-Csv | Where-Object { $_. 'Privilege Name' -eq 'SeDelegateSessionUserImpersonatePrivilege' }
  if ($privs.State -eq "Disabled") {
    Write-Verbose "Running with user privileges"

    # Invoke-HPPrivateNotificationAsUser is modeled after Invoke-HPPrivateRebootNotificationAsUser so using -NoDismiss instead of -Dismiss for consistency 
    if($Dismiss) {
      Invoke-HPPrivateNotificationAsUser -Title $Title -Message $Message -LogoImage $LogoImage -Expiration $Expiration -Attribution $Id -Signature $Signature -NoDismiss "false"
    }
    else {
      Invoke-HPPrivateNotificationAsUser -Title $Title -Message $Message -LogoImage $LogoImage -Expiration $Expiration -Attribution $Id -Signature $Signature -NoDismiss "true" 
    }
  }
  else {
    Write-Verbose "Running with system privileges"

    try {
      $psPath = (Get-Process -Id $pid).Path

      # Passing the parameters as environment variable because the following block executes in a different context
      [System.Environment]::SetEnvironmentVariable('HPNotificationTitle',$Title,[System.EnvironmentVariableTarget]::Machine)
      [System.Environment]::SetEnvironmentVariable('HPNotificationMessage',$Message,[System.EnvironmentVariableTarget]::Machine)
      [System.Environment]::SetEnvironmentVariable('HPNotificationSignature',$Signature,[System.EnvironmentVariableTarget]::Machine)
      [System.Environment]::SetEnvironmentVariable('HPNotificationAttribution',$Id,[System.EnvironmentVariableTarget]::Machine)

      if ($LogoImage) {
        [System.Environment]::SetEnvironmentVariable('HPNotificationLogoImage',$LogoImage,[System.EnvironmentVariableTarget]::Machine)
      }
      if ($Expiration) {
        [System.Environment]::SetEnvironmentVariable('HPNotificationExpiration',$Expiration,[System.EnvironmentVariableTarget]::Machine)
      }

      # environment variables can only be strings, so we need to convert the Dismiss boolean to a string
      if($Dismiss) {
        [System.Environment]::SetEnvironmentVariable('HPNotificationNoDismiss', "false",[System.EnvironmentVariableTarget]::Machine)
      }
      else {
        [System.Environment]::SetEnvironmentVariable('HPNotificationNoDismiss', "true",[System.EnvironmentVariableTarget]::Machine)
      }
   
      [scriptblock]$scriptBlock = {
        $path = $pwd.Path
        Import-Module -Force $path\HP.Notifications.psd1
        $params = @{
          Title = $env:HPNotificationTitle
          Message = $env:HPNotificationMessage
          Signature = $env:HPNotificationSignature
          Attribution = $env:HPNotificationAttribution
          NoDismiss = $env:HPNotificationNoDismiss
        }

        if ($env:HPNotificationLogoImage) {
          $params.LogoImage = $env:HPNotificationLogoImage
        }
       
        if ($env:HPNotificationExpiration) {
          $params.Expiration = $env:HPNotificationExpiration
        }

        Invoke-HPPrivateNotificationAsUser @params
      }

      $encodedCommand = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($scriptBlock))
      $psCommand = "-ExecutionPolicy Bypass -Window Normal -EncodedCommand $($encodedCommand)"
      [ProcessExtensions]::StartProcessAsCurrentUser($psPath,"`"$psPath`" $psCommand",$PSScriptRoot)

      [System.Environment]::SetEnvironmentVariable('HPNotificationTitle',$null,[System.EnvironmentVariableTarget]::Machine)
      [System.Environment]::SetEnvironmentVariable('HPNotificationMessage',$null,[System.EnvironmentVariableTarget]::Machine)
      [System.Environment]::SetEnvironmentVariable('HPNotificationSignature',$null,[System.EnvironmentVariableTarget]::Machine)
      [System.Environment]::SetEnvironmentVariable('HPNotificationAttribution',$null,[System.EnvironmentVariableTarget]::Machine)
      [System.Environment]::SetEnvironmentVariable('HPNotificationNoDismiss',$null,[System.EnvironmentVariableTarget]::Machine)

      if ($LogoImage) {
        [System.Environment]::SetEnvironmentVariable('HPNotificationLogoImage',$null,[System.EnvironmentVariableTarget]::Machine)
      }
      if ($Expiration) {
        [System.Environment]::SetEnvironmentVariable('HPNotificationExpiration',$null,[System.EnvironmentVariableTarget]::Machine)
      }
    }
    catch {
      Write-Error -Message "Could not execute as currently logged on user: $($_.Exception.Message)" -Exception $_.Exception
    }
  }

  # add a delay before unregistering the app because if you unregister the app right away, toast notification won't pop up 
  Start-Sleep -Seconds 5
  Unregister-NotificationApplication -Id $Id

  return
}


# SIG # Begin signature block
# MIIoHgYJKoZIhvcNAQcCoIIoDzCCKAsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBjAuiLBzgochl5
# X+OcY0oMEXMhVII4S4RxTv8+cOGCQKCCDYowggawMIIEmKADAgECAhAIrUCyYNKc
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
# KwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEID3YSgLp
# aiOsr5a3MeCJqrMqdkgepBOlieiYYej4fVOQMA0GCSqGSIb3DQEBAQUABIIBgC9H
# ZXdULTgJ3251vDlmKd53inCED3gFr7ZonPfOFAcAE8ZpJHOxPRv8GFcK2jp0FGwr
# Zc5VCICiatl3jZ9KXltoqhvK1sV26RTo9MgAtbcchSmZNCrfMgXCIUh+hdaSJ2Y6
# bvfVjwahl2286xuaXJNKHh8RviLjb8+/9OHVXOXU7tNDFZk37WX3HmZnEg2fGou4
# fGNKir8E3iawGytPrhOd3dSUeQwN+wF79a8svwMs8NVD/lrURRHEj2Nw8Rbj3ZyG
# 14PDtXpT/ZS/yAOJAm36hHH8ApQmFNZT5ViAyqBsoctpochkWZCZxG75n9I1B/oz
# ES0URbrIQphnyYrK0A2JosqO3lCb7Ocl5a5RVgaEYYIMhbgbPRp0tsUd27d8cLLn
# JhbZOc1+hHnZgb01c6X/WPNUY5SkKhCBymhyMZ2PzujNFIwNKDmR1akjFc/dp7oX
# acA5khzrC45P84c3EKIpir5+QoEUx+5XaZ9McXqxo72VTjoVOyd32iXtm/2PiKGC
# F0Awghc8BgorBgEEAYI3AwMBMYIXLDCCFygGCSqGSIb3DQEHAqCCFxkwghcVAgED
# MQ8wDQYJYIZIAWUDBAIBBQAweAYLKoZIhvcNAQkQAQSgaQRnMGUCAQEGCWCGSAGG
# /WwHATAxMA0GCWCGSAFlAwQCAQUABCACblAuZEB+VgglPYUGtFSE+QCCpk7Fka3H
# NkkbOCjoWQIRAMb9GGI3ueowreDUujZ1kCMYDzIwMjQwODI3MTY1NTUwWqCCEwkw
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
# CQQxIgQgrNL/BELOIDwLIjCf0y6f5ZB7f044MZK201lyUD+IDHcwNwYLKoZIhvcN
# AQkQAi8xKDAmMCQwIgQg0vbkbe10IszR1EBXaEE2b4KK2lWarjMWr00amtQMeCgw
# DQYJKoZIhvcNAQEBBQAEggIAUfRBlKp1d2SWzzV2fFZrAcmsJzuaJ6SyS7jp/Lzo
# yZGQEPh1ldhawreqJtUygRAvbmLx0UUvekiwigAAysWQsW1yQ5U2bhIvtTElUVWp
# EsYoXHg2yDgsJvNZK0bn3otJle03XFq4A2t8N6nhKaTG19RyOCs7RzQz23RlnUwa
# ZPhDzu4ur/O2jA1WNi19uCdXppJZWGb5ItawqTP4YFy43bU7cVcd+bDAL7nrpoA2
# l/gIP4FBGwt6m7N0hF8F6stqJ48kEX4kIbd8BlAmuAwuRq+GczBw6BvD4RBudDp5
# R4y/MeU7d8mtEasrk3rK9l/gZNFIIvgIYyoYZDzb8IK92XFxgbjLS84dLPZo+aOF
# QXDVMDxqVxTknl5hdIWbRZTJlBjAk5/GuSTHZrVUpsXpCRCYqMS9U7HWyMmsaG8L
# q0idbNH8+UUjKuOtsDWUylrkIXegCjpazzOn1VepBjaPFb10uh+scXYcylK98gId
# lDIFV/GhnlwATVV/HrpvK5QY0ZUf15sR+KiL6oG9odRXJUppI0jeLhBZhRpIVsnt
# tHCe+eH8I/h2FVtz4ZOqjABHtZGpNPtt3DxNmvDtDEWFp28rHt+KBwrEfvND0OAG
# 7YHta2rJCr5kLRcu1atx/Mm3Jy0dSljMAbVR8yiXMvsT2OH0A+n1Ha2yxkwiqxBJ
# KUI=
# SIG # End signature block
