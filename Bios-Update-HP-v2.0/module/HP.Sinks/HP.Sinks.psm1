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

# CMSL is normally installed in C:\Program Files\WindowsPowerShell\Modules
# but if installed via PSGallery and via PS7, it is installed in a different location
if (Test-Path "$PSScriptRoot\..\HP.Private\HP.CMSLHelper.dll") {
  Add-Type -Path "$PSScriptRoot\..\HP.Private\HP.CMSLHelper.dll"
}
else{
  Add-Type -Path "$PSScriptRoot\..\..\HP.Private\1.7.2\HP.CMSLHelper.dll"
}


enum LogType{
  Simple
  CMTrace
}

enum LogSeverity{
  Information = 1
  Warning = 2
  Error = 3
}

function Get-HPPrivateThreadID { [Threading.Thread]::CurrentThread.ManagedThreadId }
function Get-HPPrivateUserIdentity { [System.Security.Principal.WindowsIdentity]::GetCurrent().Name }
function Get-HPPrivateLogVar { $Env:HPCMSL_LOG_FORMAT }

<#
.SYNOPSIS
  Sends a message to a syslog server

.DESCRIPTION
  This command forwards data to a syslog server. This command currently supports UDP (default) and TCP connections. For more information, see RFC 5424 in the 'See also' section.

.PARAMETER message
  Specifies the message to send

.PARAMETER severity
  Specifies the severity of the message. If not specified, the severity defaults to 'Informational'.

.PARAMETER facility
  Specifies the facility of the message. If not specified, the facility defaults to 'User Message'. 

.PARAMETER clientname
  Specifies the client name. If not specified, this command uses the current computer name.

.PARAMETER timestamp
  Specifies the event time stamp. If not specified, this command uses the current time.

.PARAMETER port
  Specifies the target port. If not specified and HPSINK_SYSLOG_MESSAGE_TARGET_PORT is not set, this command uses port 514 for both TCP and UDP.

.PARAMETER tcp
  If specified, this command uses TCP instead of UDP. Default is UDP. Switching to TCP may generate additional traffic but allows the protocol to acknowledge delivery.

.PARAMETER tcpframing
  Specifies octet-counting or non-transparent-framing TCP framing. This parameter only applies if the -tcp parameter is specified. Default value is octet-counting unless HPSINK_SYSLOG_MESSAGE_TCPFRAMING is specified. For more information, see RFC 6587 in the "See also" section.

.PARAMETER maxlen
  Specifies maximum length (in bytes) of message that the syslog server accepts. Common sizes are between 480 and 2048 bytes. Default is 2048 if not specified and HPSINK_SYSLOG_MESSAGE_MAXLEN is not set.

.PARAMETER target
  Specifies the target computer on which to perform this operation. Local computer is assumed if not specified and HPSINK_SYSLOG_MESSAGE_TARGET is not set.

.PARAMETER PassThru
  If specified, this command sends the message to the pipeline upon completion and any error in the command is non-terminating.


.NOTES

  This command supports the following environment variables. These overwrite the defaults documented above.

  - HPSINK_SYSLOG_MESSAGE_TARGET_PORT: override default target port
  - HPSINK_SYSLOG_MESSAGE_TCPFRAMING: override TCP Framing format
  - HPSINK_SYSLOG_MESSAGE_MAXLEN: override syslog message max length
  - HPSINK_SYSLOG_MESSAGE_TARGET: override host name of the syslog server


  Defaults can be configured via the environment. This affects all related commands. For example, when applying them to eventlog-related commands, all eventlog-related commands are affected.

  In the following example, the HPSINK_EVENTLOG_MESSAGE_TARGET and HPSINK_EVENTLOG_MESSAGE_SOURCE variables affect both the Register-EventLogSink and Send-ToEventLog commands.

  ```PowerShell
  $ENV:HPSINK_EVENTLOG_MESSAGE_TARGET="remotesyslog.mycompany.com"
  $ENV:HPSINK_EVENTLOG_MESSAGE_SOURCE="mysource"
  Register-EventLogSink
  "hello" | Send-ToEventLog
  ```


.INPUTS
  The message can be piped to this command, rather than provided via the -message parameter.

.OUTPUTS
  If the -PassThru parameter is specified, the original message is returned. This allows chaining multiple SendTo-XXX commands.

.EXAMPLE
   "hello" | Send-ToSyslog -tcp -server mysyslogserver.mycompany.com

   This sends "hello" to the syslog server on mysyslogserver.mycompany.com via TCP. Alternately, the syslog server could be set in the environment variable HPSINK_SYSLOG_MESSAGE_TARGET.

.LINK
    [RFC 5424 - "The Syslog Protocol"](https://tools.ietf.org/html/rfc5424)

.LINK
  [RFC 6587 - "Transmission of Syslog Messages over TCP"](https://tools.ietf.org/html/rfc6587)

.LINK
  [Send-ToEventlog](https://developers.hp.com/hp-client-management/doc/Send-ToEventLog)


#>
function Send-ToSyslog
{
  [CmdletBinding(HelpUri = "https://developers.hp.com/hp-client-management/doc/Send-ToSyslog")]
  param
  (
    [ValidateNotNullOrEmpty()][Parameter(Position = 0,ValueFromPipeline = $True,Mandatory = $True)] $message,
    [Parameter(Position = 1,Mandatory = $false)] [syslog_severity_t]$severity = [syslog_severity_t]::informational,
    [Parameter(Position = 2,Mandatory = $false)] [syslog_facility_t]$facility = [syslog_facility_t]::user_message,
    [Parameter(Position = 3,Mandatory = $false)] [string]$clientname,
    [Parameter(Position = 4,Mandatory = $false)] [string]$timestamp,
    [Parameter(Position = 5,Mandatory = $false)] [int]$port = $HPSINK:HPSINK_SYSLOG_MESSAGE_TARGET_PORT,
    [Parameter(Position = 6,Mandatory = $false)] [switch]$tcp,
    [ValidateSet("octet-counting","non-transparent-framing")][Parameter(Position = 7,Mandatory = $false)] [string]$tcpframing = $ENV:HPSINK_SYSLOG_MESSAGE_TCPFRAMING,
    [Parameter(Position = 8,Mandatory = $false)] [int]$maxlen = $ENV:HPSINK_SYSLOG_MESSAGE_MAXLEN,
    [Parameter(Position = 9,Mandatory = $false)] [switch]$PassThru,
    [Parameter(Position = 10,Mandatory = $false)] [string]$target = $ENV:HPSINK_SYSLOG_MESSAGE_TARGET
  )

  # Create a UDP Client Object
  $tcpclient = $null
  $use_tcp = $false


  #defaults (change these in environment)
  if ($target -eq $null -or $target -eq "") { throw "parameter $target is required" }
  if ($tcpframing -eq $null -or $tcpframing -eq "") { $tcpframing = "octet-counting" }
  if ($port -eq 0) { $port = 514 }
  if ($maxlen -eq 0) { $maxlen = 2048 }


  if ($tcp.IsPresent -eq $false) {
    switch ([int]$ENV:HPSINK_SYSLOG_MESSAGE_USE_TCP) {
      0 { $use_tcp = $false }
      1 { $use_tcp = $true }
    }
  }
  else { $use_tcp = $tcp.IsPresent }


  Write-Verbose "Sending message to syslog server"
  if ($use_tcp) {
    Write-Verbose "TCP Connection to $target`:$port"
    $client = New-Object System.Net.Sockets.TcpClient
  }
  else
  {
    Write-Verbose "UDP Connection to $target`:$port"
    $client = New-Object System.Net.Sockets.UdpClient
  }

  try {
    $client.Connect($target,$port)
  }
  catch {
    if ($_.Exception.innerException -ne $null) {
      Write-Error $_.Exception.innerException.Message -Category ConnectionError -ErrorAction Stop
    } else {
      Write-Error $_.Exception.Message -Category ConnectionError -ErrorAction Stop
    }
  }

  if ($use_tcp -and -not $client.Connected)
  {
    $prefix = "udp"
    if ($use_tcp) { $prefix = $tcp }
    throw "Could not connect to syslog host $prefix`://$target`:$port"
  }


  Write-Verbose "Syslog faciliy=$($facility.value__), severity=$($severity.value__)"

  $priority = ($facility.value__ * 8) + $severity.value__
  Write-Verbose "Priority is $priority"

  if (($clientname -eq "") -or ($clientname -eq $null)) {
    Write-Verbose "Defaulting to client = $($ENV:computername)"
    $clientname = $env:computername
  }

  if (($timestamp -eq "") -or ($timestamp -eq $null)) {
    $timestamp = Get-Date -Format "yyyy:MM:dd:-HH:mm:ss zzz"
    Write-Verbose "Defaulting to timestamp = $timestamp"
  }

  $msg = "<{0}>{1} {2} {3}" -f $priority,$timestamp,$hostname,$message

  Write-Verbose ("Sending the message: $msg")
  if ($use_tcp) {
    Write-Verbose ("Sending via TCP")


    if ($msg.Length -gt $maxlen) {
      $maxlen = $maxlen - ([string]$maxlen).Length
      Write-Verbose ("This message has been truncated because maximum effective length is $maxlen but the message is  $($msg.length) ")
      $msg = $msg.substring(0,$maxlen - ([string]$maxlen).Length)
    }

    switch ($tcpframing) {
      "octet-counting" {
        Write-Verbose "Encoding TCP payload with 'octet-counting'"
        $encoded = '{0} {1}' -f $msg.Length,$msg
        $bytes = [System.Text.Encoding]::ASCII.GetBytes($encoded)
      }

      "non-transparent-framing" {
        Write-Verbose "Encoding with 'non-transparent-framing'"
        $encoded = '{0}{1}' -f $msg.Length,$msg
        $bytes = [System.Text.Encoding]::ASCII.GetBytes($encoded)
      }
    }

    try {
      [void]$client.getStream().Write($bytes,0,$bytes.Length)
    }
    catch {
      throw ("Could not send syslog message: $($_.Exception.Message)")
    }
  }
  else
  {

    Write-Verbose ("Sending via UDP")
    try {
      $bytes = [System.Text.Encoding]::ASCII.GetBytes($msg)
      if ($bytes.Length -gt $maxlen) {
        Write-Verbose ("This message has been truncated, because maximum length is $maxlen but the message is  $($bytes.length) ")
        $bytes = $bytes[0..($maxlen - 1)]
      }
      [void]$client.Send($bytes,$bytes.Length)
    }
    catch {
      if (-not $PassThru.IsPresent) {
        throw ("Could not send syslog message: $($_.Exception.Message)")
      }
      else
      {
        Write-Error -Message $_.Exception.Message -ErrorAction Continue
      }

    }
  }

  Write-Verbose "Send complete"
  $client.Close();
  if ($PassThru) { return $message }
}


<#
.SYNOPSIS
  Registers a source in an event log

.DESCRIPTION
  This command registers a source in an event log. must be executed before sending messages to the event log via the Send-ToEventLog command. 
  The source must match the source in the Send-ToEventLog command. By default, it is assumed that the source is 'HP-CSL'.

  This command can be unregistered using the Unregister-EventLogSink command. 

.PARAMETER logname
  Specifies the log section in which to register this source

.PARAMETER source
  Specifies the event log source that will be used when logging.

  The source can also be specified via the HPSINK_EVENTLOG_MESSAGE_SOURCE environment variable.

.PARAMETER target
  Specifies the target computer on which to perform this command. Local computer is assumed if not specified, unless environment variable HPSINK_EVENTLOG_MESSAGE_TARGET is defined.

  Important: the user identity running the PowerShell script must have permissions to write to the remote event log.

.NOTES
  This command reads the following environment variables for setting defaults:

    - HPSINK_EVENTLOG_MESSAGE_SOURCE: override default source name
    - HPSINK_EVENTLOG_MESSAGE_LOG: override default message log name
    - HPSINK_EVENTLOG_MESSAGE_TARGET: override event log server name

.LINK
  [Unregister-EventLogSink](https://developers.hp.com/hp-client-management/doc/Unregister-EventLogSink)

.LINK
  [Send-ToEventLog](https://developers.hp.com/hp-client-management/doc/Send-ToEventLog)

.EXAMPLE
  Register-EventLogSink
#>
function Register-EventLogSink
{
  [CmdletBinding(HelpUri = "https://developers.hp.com/hp-client-management/doc/Register-EventLogSink")]
  param
  (
    [Parameter(Position = 0,Mandatory = $false)] [string]$logname = $ENV:HPSINK_EVENTLOG_MESSAGE_LOG,
    [Parameter(Position = 1,Mandatory = $false)] [string]$source = $ENV:HPSINK_EVENTLOG_MESSAGE_SOURCE,
    [Parameter(Position = 2,Mandatory = $false)] [string]$target = $ENV:HPSINK_EVENTLOG_MESSAGE_TARGET
  )


  #defaults (change these in environment)
  if ($source -eq $null -or $source -eq "") { $source = "HP-CSL" }
  if ($logname -eq $null -or $logname -eq "") { $logname = "Application" }
  if ($target -eq $null -or $target -eq "") { $target = "." }


  Write-Verbose "Registering source $logname / $source"
  $params = @{
    LogName = $logname
    source = $source
  }

  if ($target -ne ".") { $params.Add("ComputerName",$target) }
  New-EventLog @params
}

<#
.SYNOPSIS
   Unregisters a source registered by the Register-EventLogSink command 

.DESCRIPTION
  This command removes a registration that was previously registered by the Register-EventLogSink command. 

Note:
Switching between formats changes the file encoding. The 'Simple' mode uses unicode encoding (UTF-16) while the 'CMTrace' mode uses UTF-8. This is partly due to historical reasons
(default encoding in UTF1-16 and existing log is UTF-16) and partly due to limitations in CMTrace tool, which seems to have trouble with UTF-16 in some cases. 

As a result, it is important to start with a new log when switching modes. Writing UTF-8 to UTF-16 files or vice versa will cause encoding and display issues.  

.PARAMETER source  
  Specifies the event log source that was registered via the Register-EventLogSink command. The source can also be specified via the HPSINK_EVENTLOG_MESSAGE_SOURCE environment variable.

.PARAMETER target
  Specifies the target computer on which to perform this command. Local computer is assumed if not specified, unless environment variable
  HPSINK_EVENTLOG_MESSAGE_TARGET is defined.

  Important: the user identity running the PowerShell script must have permissions to write to the remote event log.

.NOTES
    This command reads the following environment variables for setting defaults:

  - HPSINK_EVENTLOG_MESSAGE_SOURCE: override default source name
  - HPSINK_EVENTLOG_MESSAGE_TARGET: override event log server name

.LINK
  [Register-EventLogSink](https://developers.hp.com/hp-client-management/doc/Register-EventLogSink)

.LINK
  [Send-ToEventLog](https://developers.hp.com/hp-client-management/doc/Send-ToEventLog)

.EXAMPLE
  Unregister-EventLogSink
#>
function Unregister-EventLogSink
{
  [CmdletBinding(HelpUri = "https://developers.hp.com/hp-client-management/doc/Unregister-EventLogSink")]
  param
  (
    [Parameter(Position = 0,Mandatory = $false)] [string]$source = $ENV:HPSINK_EVENTLOG_MESSAGE_SOURCE,
    [Parameter(Position = 1,Mandatory = $false)] [string]$target = $ENV:HPSINK_EVENTLOG_MESSAGE_TARGET
  )

  #defaults (change these in environment)
  if ($source -eq $null -or $source -eq "") { $source = "HP-CSL" }
  if ($target -eq $null -or $target -eq "") { $target = "." }


  Write-Verbose "Unregistering source $source"
  $params = @{
    source = $source
  }

  if ($target -ne ".") { $params.Add("ComputerName",$target) }
  Remove-EventLog @params
}

<#
.SYNOPSIS
  Sends a message to an event log

.DESCRIPTION
  This command sends a message to an event log. 

  The source should be initialized with the Register-EventLogSink command to register the source name prior to using this command. 

.PARAMETER id
  Specifies the event id that will be registered under the 'Event ID' column in the event log. Default value is 0. 

.PARAMETER source
  Specifies the event log source that will be used when logging. This source should be registered via the Register-EventLogSink command. 

  The source can also be specified via the HPSINK_EVENTLOG_MESSAGE_SOURCE environment variable.

.PARAMETER message
  Specifies the message to log. This parameter is required.

.PARAMETER severity
  Specifies the severity of the message. If not specified, the severity is set as 'Information'.

.PARAMETER category
  Specifies the category of the message. The category shows up under the 'Task Category' column. If not specified, it is 'General', unless environment variable HPSINK_EVENTLOG_MESSAGE_CATEGORY is defined.

.PARAMETER logname
  Specifies the log in which to log (e.g. Application, System, etc). If not specified, it will log to Application, unless environment variable HPSINK_EVENTLOG_MESSAGE_LOG is defined.

.PARAMETER rawdata
  Specifies any raw data to add to the log entry 

.PARAMETER target
  Specifies the target computer on which to perform this operation. Local computer is assumed if not specified, unless environment variable HPSINK_EVENTLOG_MESSAGE_TARGET is defined.

  Important: the user identity running the PowerShell script must have permissions to write to the remote event log.

.PARAMETER PassThru
  If specified, this command sends the message to the pipeline upon completion and any error in the command is non-terminating.

.EXAMPLE 
    "hello" | Send-ToEventLog 

.NOTES
    This command reads the following environment variables for setting defaults.

  - HPSINK_EVENTLOG_MESSAGE_SOURCE: override default source name
  - HPSINK_EVENTLOG_MESSAGE_CATEGORY: override default category id
  - HPSINK_EVENTLOG_MESSAGE_LOG: override default message log name
  - HPSINK_EVENTLOG_MESSAGE_TARGET: override event log server name

  Defaults can be configured via the environment. This affects all related commands. For example, when applying them to eventlog-related commands, all eventlog-related commands are affected.

  In the following example, the HPSINK_EVENTLOG_MESSAGE_TARGET and HPSINK_EVENTLOG_MESSAGE_SOURCE variables affect both the Register-EventLogSink and Send-ToEventLog commands.

  ```PowerShell
  $ENV:HPSINK_EVENTLOG_MESSAGE_TARGET="remotesyslog.mycompany.com"
  $ENV:HPSINK_EVENTLOG_MESSAGE_SOURCE="mysource"
  Register-EventLogSink
  "hello" | Send-ToEventLog
  ```


.LINK
  [Unregister-EventLogSink](https://developers.hp.com/hp-client-management/doc/Unregister-EventLogSink)

.LINK
  [Register-EventLogSink](https://developers.hp.com/hp-client-management/doc/Register-EventLogSink)

.LINK
  [Send-ToSyslog](https://developers.hp.com/hp-client-management/doc/Send-ToSyslog)


#>
function Send-ToEventLog
{
  [CmdletBinding(HelpUri = "https://developers.hp.com/hp-client-management/doc/Send-ToEventlog")]
  param
  (

    [Parameter(Position = 0,Mandatory = $false)] [string]$source = $ENV:HPSINK_EVENTLOG_MESSAGE_SOURCE,
    [Parameter(Position = 1,Mandatory = $false)] [int]$id = 0,
    [ValidateNotNullOrEmpty()][Parameter(Position = 2,ValueFromPipeline = $true,Mandatory = $True)] $message,
    [Parameter(Position = 3,Mandatory = $false)] [eventlog_severity_t]$severity = [eventlog_severity_t]::informational,
    [Parameter(Position = 4,Mandatory = $false)] [int16]$category = $ENV:HPSINK_EVENTLOG_MESSAGE_CATEGORY,
    [Parameter(Position = 5,Mandatory = $false)] [string]$logname = $ENV:HPSINK_EVENTLOG_MESSAGE_LOG,
    [Parameter(Position = 6,Mandatory = $false)] [byte[]]$rawdata = $null,
    [Parameter(Position = 7,Mandatory = $false)] [string]$target = $ENV:HPSINK_EVENTLOG_MESSAGE_TARGET,
    [Parameter(Position = 8,Mandatory = $false)] [switch]$PassThru
  )

  #defaults (change these in environment)
  if ($source -eq $null -or $source -eq "") { $source = "HP-CSL" }
  if ($logname -eq $null -or $logname -eq "") { $logname = "Application" }
  if ($target -eq $null -or $target -eq "") { $target = "." }

  Write-Verbose "Sending message (category=$category, id=$id) to eventlog $logname with source $source"
  $params = @{
    EntryType = $severity.value__
    Category = $category
    Message = $message
    LogName = $logname
    source = $source
    EventId = $id
  }


  if ($target -ne ".") {
    $params.Add("ComputerName",$target)
    Write-Verbose ("The target machine is remote ($target)")
  }

  if ($rawdata -ne $null) { $params.Add("RawData",$rawdata) }

  try {
    Write-EventLog @params
  }
  catch {
    if (-not $PassThru.IsPresent) {
      throw ("Could not send eventlog message: $($_.Exception.Message)")
    }
    else
    {
      Write-Error -Message $_.Exception.Message -ErrorAction Continue
    }
  }
  if ($PassThru) { return $message }
}




<#
.SYNOPSIS
   Writes a 'simple' LOG entry
   Private command. Do not export
#>
function Write-HPPrivateSimple {

  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $True,Position = 0)]
    [LogSeverity]$Severity,
    [Parameter(Mandatory = $True,Position = 1)]
    [string]$Message,
    [Parameter(Mandatory = $True,Position = 2)]
    [string]$Component,
    [Parameter(Mandatory = $False,Position = 3)]
    [string]$File = $Null
  )
  $prefix = switch ($severity) {
    Error { " [ERROR] " }
    Warning { " [WARN ] " }
    default { "" }
  }

  if ($File) {
    if (-not [System.IO.Directory]::Exists([System.IO.Path]::GetDirectoryName($File)))
    {
      throw [System.IO.DirectoryNotFoundException]"Path not found: $([System.IO.Path]::GetDirectoryName($File))"
    }
  }

  $context = Get-HPPrivateUserIdentity

  $line = "[$(Get-Date -Format o)] $Context  - $Prefix $Message"
  if ($File) {
    $line | Out-File -Width 1024 -Append -Encoding unicode -FilePath $File
  }
  else {
    $line
  }

}

<#
.SYNOPSIS
   Writes a 'CMTrace' LOG entry
   Private command. Do not export
#>
function Write-HPPrivateCMTrace {
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $True,Position = 0)]
    [LogSeverity]$Severity,
    [Parameter(Mandatory = $True,Position = 1)]
    [string]$Message,
    [Parameter(Mandatory = $True,Position = 2)]
    [string]$Component,
    [Parameter(Mandatory = $False,Position = 3)]
    [string]$File

  )

  $line = "<![LOG[$Message]LOG]!>" + `
     "<time=`"$(Get-Date -Format "HH:mm:ss.ffffff")`" " + `
     "date=`"$(Get-Date -Format "M-d-yyyy")`" " + `
     "component=`"$Component`" " + `
     "context=`"$(Get-HPPrivateUserIdentity)`" " + `
     "type=`"$([int]$Severity)`" " + `
     "thread=`"$(Get-HPPrivateThreadID)`" " + `
     "file=`"`">"

  if ($File) {
    if (-not [System.IO.Directory]::Exists([System.IO.Path]::GetDirectoryName($File)))
    {
      throw [System.IO.DirectoryNotFoundException]"Path not found: $([System.IO.Path]::GetDirectoryName($File))"
    }
  }

  if ($File) {
    $line | Out-File -Append -Encoding UTF8 -FilePath $File -Width 1024
  }
  else {
    $line
  }

}




<#
.SYNOPSIS
  Sets the format used by the Write-Log* commands 

.DESCRIPTION
  This command sets the log format used by the Write-Log* commands. The two formats supported are simple (human readable) format and CMtrace format used by configuration manager.

  The format is stored in the HPCMSL_LOG_FORMAT environment variable. To set the default format without using this command, update the variable by setting it to either 'Simple' or 'CMTrace' ahead of time.

  The default format is 'Simple'. 

.PARAMETER Format
  Specifies the log format. The value must be one of the following values:
  - Simple: human readable
  - CMTrace: XML format used by the CMTrace tool

.EXAMPLE
  Set-HPCMSLLogFormat -Format CMTrace

.LINK
  [Write-LogInfo](https://developers.hp.com/hp-client-management/doc/Write-LogInfo)

.LINK
  [Write-LogWarning](https://developers.hp.com/hp-client-management/doc/Write-LogWarning)

.LINK
  [Write-LogError](https://developers.hp.com/hp-client-management/doc/Write-LogError)

.LINK
  [Get-HPCMSLLogFormat](https://developers.hp.com/hp-client-management/doc/Get-HPCMSLLogFormat)

#>
function Set-HPCMSLLogFormat
{
  [CmdletBinding(HelpUri = "https://developers.hp.com/hp-client-management/doc/Set-HPCMSLLogFormat")]
  param(
    [Parameter(Mandatory = $True,Position = 0)]
    [LogType]$Format
  )
  $Env:HPCMSL_LOG_FORMAT = $Format
  $Global:CmslLog = $Global:CmslLogType

  Write-Debug "Set log type to $($Global:CmslLog)"
}

<#
.SYNOPSIS
  Retrieves the format used by the log commands
  
.DESCRIPTION
  This command retrieves the configured log format used by the Write-Log* commands. This command returns the value of the HPCMSL_LOG_FORMAT environment variable or 'Simple' if the variable is not configured.

.PARAMETER Format
  Specifies the log format. The value must be one of the following values:
  - Simple: human readable
  - CMTrace: XML format used by the CMTrace tool

.EXAMPLE
  Get-HPCMSLLogFormat -Format CMTrace

.LINK
  [Write-LogInfo](https://developers.hp.com/hp-client-management/doc/Write-LogInfo)
.LINK
  [Write-LogWarning](https://developers.hp.com/hp-client-management/doc/Write-LogWarning)
.LINK  
  [Write-LogError](https://developers.hp.com/hp-client-management/doc/Write-LogError)
.LINK  
  [Set-HPCMSLLogFormat](https://developers.hp.com/hp-client-management/doc/Set-HPCMSLLogFormat)

#>
function Get-HPCMSLLogFormat
{
  [CmdletBinding(HelpUri = "https://developers.hp.com/hp-client-management/doc/Get-HPCMSLLogFormat")]
  param()

  if (-not $Global::CmslLog)
  {
    $Global:CmslLog = Get-HPPrivateLogVar
  }

  if (-not $Global:CmslLog)
  {
    $Global:CmslLog = 'Simple'
  }

  Write-Verbose "Configured log type is $($Global:CmslLog)"

  switch ($Global:CmslLog)
  {
    'CMTrace' { 'CMTrace' }
    Default { 'Simple' }
  }

}


<#
.SYNOPSIS
  Writes a 'warning' log entry
  
.DESCRIPTION
  This command writes a 'warning' log entry to default output or a specified file.

.PARAMETER Message
  Specifies the message to write

.PARAMETER Component
  Specifies a 'Component' tag for the message entry. Some log readers use this parameter to group messages. If not specified, the component tag is 'General'.
  This parameter is ignored in 'Simple' mode due to backwards compatibility reasons.

.PARAMETER File
  Specifies the file to update with the new log entry. If not specified, the log entry is written to the pipeline.

.EXAMPLE
  Write-LogWarning -Component "Repository" -Message "Something bad may have happened" -File myfile.log

.LINK
  [Write-LogInfo](https://developers.hp.com/hp-client-management/doc/Write-LogInfo)
.LINK  
  [Write-LogError](https://developers.hp.com/hp-client-management/doc/Write-LogError)
.LINK  
  [Get-HPCMSLLogFormat](https://developers.hp.com/hp-client-management/doc/Get-HPCMSLLogFormat)
.LINK  
  [Set-HPCMSLLogFormat](https://developers.hp.com/hp-client-management/doc/Set-HPCMSLLogFormat)

#>
function Write-LogWarning
{
  [CmdletBinding(HelpUri = "https://developers.hp.com/hp-client-management/doc/Write-LogWarning")]
  param(
    [Parameter(Mandatory = $True,Position = 0)]
    [string]$Message,
    [Parameter(Mandatory = $False,Position = 1)]
    [string]$Component = "General",
    [Parameter(Mandatory = $False,Position = 2)]
    [string]$File
  )
  if ($File) {
    $file = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($file)
  }
  switch (Get-HPCMSLLogFormat)
  {
    CMTrace {
      Write-HPPrivateCMTrace -Severity Warning -Message $Message -Component $Component -File $File
    }
    default {
      Write-HPPrivateSimple -Severity Warning -Message $Message -Component $Component -File $file
    }
  }


}


<#
.SYNOPSIS
  Writes an 'error' log entry
  
.DESCRIPTION
  This command writes an 'error' log entry to default output or a specified file.

.PARAMETER Message
  Specifies the message to write

.PARAMETER Component
  Specifies a 'Component' tag for the message entry. Some log readers use this parameter to group messages. If not specified, the component tag is 'General'.
  This parameter is ignored in 'Simple' mode due to backwards compatibility reasons.

.PARAMETER File
  Specifies the file to update with the new log entry. If not specified, the log entry is written to pipeline.

.EXAMPLE
  Write-LogError -Component "Repository" -Message "Something bad happened" -File myfile.log

.LINK
  [Write-LogInfo](https://developers.hp.com/hp-client-management/doc/Write-LogInfo)
.LINK  
  [Write-LogWarning](https://developers.hp.com/hp-client-management/doc/Write-LogWarning)
.LINK  
  [Get-HPCMSLLogFormat](https://developers.hp.com/hp-client-management/doc/Get-HPCMSLLogFormat)
.LINK  
  [Set-HPCMSLLogFormat](https://developers.hp.com/hp-client-management/doc/Set-HPCMSLLogFormat)
  
#>
function Write-LogError
{
  [CmdletBinding(HelpUri = "https://developers.hp.com/hp-client-management/doc/Write-LogError")]
  param(
    [Parameter(Mandatory = $True,Position = 0)]
    [string]$Message,
    [Parameter(Mandatory = $False,Position = 1)]
    [string]$Component = "General",
    [Parameter(Mandatory = $False,Position = 2)]
    [string]$File
  )

  if ($File) {
    $file = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($file)
  }
  switch (Get-HPCMSLLogFormat)
  {
    CMTrace {
      Write-HPPrivateCMTrace -Severity Error -Message $Message -Component $Component -File $file
    }
    default {
      Write-HPPrivateSimple -Severity Error -Message $Message -Component $Component -File $file
    }
  }

}

<#
.SYNOPSIS
  Writes an 'informational' log entry
  
.DESCRIPTION
  This command writes an 'informational' log entry to default output or a specified file.

.PARAMETER Message
  Specifies the message to write

.PARAMETER Component
  Specifies a 'Component' tag for the message entry. Some log readers use this parameter to group messages. If not specified, the component tag is 'General'.
  This parameter is ignored in 'Simple' mode due to backwards compatibility reasons.

.PARAMETER File
  Specifies the file to update with the new log entry. If not specified, the log entry is written to pipeline.

.EXAMPLE
  Write-LogInfo -Component "Repository" -Message "Nothing bad happened" -File myfile.log
#>
function Write-LogInfo
{
  [CmdletBinding(HelpUri = "https://developers.hp.com/hp-client-management/doc/Write-LogInfo")]
  param(
    [Parameter(Mandatory = $True,Position = 0)]
    [string]$Message,
    [Parameter(Mandatory = $False,Position = 1)]
    [string]$Component = "General",
    [Parameter(Mandatory = $False,Position = 2)]
    [string]$File
  )
  if ($File) {
    $file = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($file)
  }

  switch (Get-HPCMSLLogFormat)
  {
    CMTrace {
      Write-HPPrivateCMTrace -Severity Information -Message $Message -Component $Component -File $file
    }
    default {
      Write-HPPrivateSimple -Severity Information -Message $Message -Component $Component -File $file
    }
  }

}

# SIG # Begin signature block
# MIIoHgYJKoZIhvcNAQcCoIIoDzCCKAsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAwQ+lh7DkBBUB4
# u1fCdErgz8T1p2rSBQGP8GHNumypzaCCDYowggawMIIEmKADAgECAhAIrUCyYNKc
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
# KwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMM7PqHS
# tmKjaCSwKi4tDN2FLn4VAeEUIDH2pW3tFs3kMA0GCSqGSIb3DQEBAQUABIIBgFHz
# YzUPbXUWq/0Uq9DdNrS2bWpYRJ6fAKPsDRy1k3XRQlDD4I36Amc2jYb7458EW1IR
# saUu4+j78rPfnACSSLUp96TSnYz//XYX1szrqsutz3EFc3WDOSm0ivmBHinttGKf
# wdOfXAxSg9qKQ027NOh3426ThO+C1pzvKpxnc0P+LQIw7l7zAx19zvnIE8S+zJmq
# 7dKqMxj3QdcGXRXCW8g59wMkRe5G0DrX7qTs1SbiRRyEjB8+NqkVCjR7wNX3sWTH
# I3FXCfweHJ54dQJLBMtkXYy37glO9phVzcdw4SXssRrL2pWEXYWygb9IC/6bLr9/
# D2EX1TAb1SrC65GAI1Koz8OLy/W34bhWrAHt179yDEiZbmqEn2rMYgibeCn4QTOa
# gOkukG88LicMFGheNZBuyl4B9iPzThymbnAyglVRQzb4gf23DYQyAnb89IoX45xM
# vub/RwaRJv8UCz4gRTgDPirsu1VtHNaXSBxQ9tU9vMdFAGCvo4kpQDDnXCZpm6GC
# F0Awghc8BgorBgEEAYI3AwMBMYIXLDCCFygGCSqGSIb3DQEHAqCCFxkwghcVAgED
# MQ8wDQYJYIZIAWUDBAIBBQAweAYLKoZIhvcNAQkQAQSgaQRnMGUCAQEGCWCGSAGG
# /WwHATAxMA0GCWCGSAFlAwQCAQUABCB32B+UIW6aD2WNJw5LcUa7yTGpw93HlkuY
# iNqOny3m7gIRAN1uupOXG4f7qBTQk1K2aXUYDzIwMjQwODI3MTY1NTUwWqCCEwkw
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
# CQQxIgQgs1j86GrPiS6qrv9Vd/N+Fec+BPNHKO591o2bSsP25B0wNwYLKoZIhvcN
# AQkQAi8xKDAmMCQwIgQg0vbkbe10IszR1EBXaEE2b4KK2lWarjMWr00amtQMeCgw
# DQYJKoZIhvcNAQEBBQAEggIAiGJmLCDA8fqFyU9lG3rmMxCcxex/VrB74WFTRxZi
# hJLeQfB9ZiNAX2qAvX4SgEfYPlYyA9JZczXTuLH8N2PxujPW7ubqiOyEczI6r/jJ
# WkvGwvD2i1am4RRCGi6lbuzsvwZkJaUhmYdbI8Ibh7H6WmZ4ajSNKstzHHmSHBh8
# Bsttv4rWpupqTodY3ixwphZk9wFEk+MV2oaYWG12fZM4Yxa2yyHDWJGAB23A2qOj
# mN4TowoupHmJgklzDU7gvlQSfg9oQAvg4OtR+N1pwQlNqH+BDUz1g3NK6v1MO7FT
# eH+dvh7j7PTA/aMg02lPztBdEYIgUlICyCIz60mbWLmpLZ9U7vdzOoQrEW2LPSHL
# LC3cc9ay9OmkuNOpC9IrZu8w/PugI7wLFn5PzONtVQO0tM2But0TJY0x2gLbP6Mo
# 0MdqCbrorVEkiBStq7k41qa/+9ZxmofXcxL764bbZGdWGxtH6UY2WR8gjtpMWmMA
# WW5c92Sl+krPKHo3F5Ifqvnt0Avx+ihL7zgicP7q39Q4II3eCBpZuqjalFckCfup
# r8/QEsxYFTYN2uwEA4xBB6OHe71j56gmcG1Ro5Hcg9Y7OyKIgIV44OUThFf0HbDu
# cwP42/IMhfPETIOqYbhPYXCZcUq/mEEJhT9NXOgw2eLSHlyucPgtpLIh+J6ObxfN
# aX4=
# SIG # End signature block
