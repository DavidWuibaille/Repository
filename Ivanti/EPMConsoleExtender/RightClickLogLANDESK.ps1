Param(
    [parameter(Mandatory=$true)][String]$Mycomputer
)

function Log {
    param(
        [string] $ficherLog,
		[string] $ValeurLog
    )
    #DD-content $ficherLog -value $ValeurLog
	$ValeurLog | Out-File $ficherLog -Append

    write-host $ValeurLog
}

function GetComputerDownloadFile {
    param (
        $mycomputer,
        $logfile
    )

    $PathLog = "\\$mycomputer\c$\Program Files (x86)\LANDESK\LDClient\CurrentDownloads.log"
    If (test-path "\\$mycomputer\c$\Program Files\LANDESK\LDClient\CurrentDownloads.log")  { $PathLog = "\\$mycomputer\c$\Program Files\LANDESK\LDClient\CurrentDownloads.log" }

    Log $logfile "************** DownloadFile ($mycomputer) **************"    
    if (test-path $PathLog) {
        $inf = Get-Content -path $PathLog -Tail 100
        Foreach ( $line in $inf ) {
            $temp = $line -Split ","
            $getDownloadFile = get-content -path $logfile  -Tail 10
            $sourceDowload =  $temp[4]
            $sourceDowload  =  $sourceDowload.Trim()
            $nameDowload = $temp[1]
            $nameDowload  =  $nameDowload.Trim()
            If ($getDownloadFile -notmatch  $sourceDowload ) {
                Log $logfile "$sourceDowload;$nameDowload"
            }
        }
    } Else {
        Log $logfile "ERROR"
    }
}



function GetComputerTaskResult {
    param (
        $mycomputer,
        $taskID,
        $logfile
    )
    Log $logfile "************** GetTaskStatus ($mycomputer) **************"

    $PathLog = "\\$mycomputer\c$\Program Files (x86)\LANDESK\LDClient\Data"
    If (test-path "\\$mycomputer\c$\Program Files\LANDESK\LDClient\Data")  { $PathLog = "\\$mycomputer\c$\Program Files\LANDESK\LDClient\Data" }

    $oldtask = "XXXXXXXXXXXXX"
    if (test-path $PathLog) {
        $Alltask = Get-ChildItem -Path $PathLog -Filter "sdclient_task*.log" -File
        Foreach ( $task in $Alltask ) {
            $Fullnametask = $task.FullName
            $nametask = $task.Name

            $nametask = $nametask.replace("sdclient_task","")
            $nametask = $nametask.replace(".log","")

            if ($nametask -like "*.*") {
                $temp2 = $nametask.Split('.')
                $nametask = $temp2[0]
            }

            if (($taskID -eq "ALL") -or ($taskID -eq $nametask)) {
                if ($nametask -ne $oldtask) { 

                    Log $logfile "************** $nametask ****************"


                } 
				
                $inf = Get-Content -path $Fullnametask  -Tail 100
                Foreach ( $line in $inf ) {
                    if ($line -like "*processing of package is complete*") {
                        $temp = $line -Split "result"
                        $Valeur = "result"+$temp[1]
                        Log $logfile $Valeur
                    }
                    if (($line -like "*Sending task status*") -and ($line -notlike "*ldap=*")) {
                        $temp = $line -Split "-retcode"
                        $Valeur = "-retcode"+$temp[1]
                        Log $logfile $Valeur
                    }
					If ($line -like "*Download Error*")  { Log $logfile $line }	
                    If ($line -like "*sdmcache*")        { Log $logfile $line }	
                }
                $oldtask = $nametask
            }
        }

    } Else {
        Log $logfile "ERROR $NameFolder"
    }
}

function GetPolicySyncLog {
    param (
        $mycomputer,
        $logfile
    )
    Log $logfile "************** GetPolicySync ($mycomputer) **************"
    $PathLog = "\\$mycomputer\c$\ProgramData\LANDesk\Log\PolicySync.exe.log"

    if (test-path $PathLog ) {
        $inf = Get-Content -path $PathLog -Tail 100
        Foreach ( $line in $inf ) {
            If ($line -like "*Run PolicySync*")                      { Log $logfile $line }
			If ($line -like "*WriteNewPolicies.DownLoadPolicyFile*") { Log $logfile $line }
			If ($line -like "*Exit PolicySync*")                     { Log $logfile $line }
			If ($line -like "*PolicyScrubber*")                      { Log $logfile $line }
			If ($line -like "*ShouldRecurring*")                     { Log $logfile $line }	
		
        }
    } Else {
        Log $logfile "ERROR"
    }
}


function GetPreferedserverDAT {
    param (
        $mycomputer,
        $logfile
    )
    Log $logfile "************** GetPreferedserverDAT ($mycomputer) **************"
    $PathLog = "\\$mycomputer\c$\Program Files (x86)\LANDesk\LDClient\sdmcache\preferredservers.dat"
    If (test-path "\\$mycomputer\c$\Program Files\LANDesk\LDClient\sdmcache\preferredservers.dat")  { $PathLog = "\\$mycomputer\c$\Program Files\LANDesk\LDClient\sdmcache\preferredservers.dat" }

	$PrefOK = 0
    if (test-path $PathLog) {
        $inf = (Get-Content -path $PathLog).replace('?','.').replace("`0", "")
		Log $logfile $inf
		$PrefOK = 0
    } 

	
	if ($PrefOK -eq 0) {
		Log $logfile "ERROR"	
	}
	
}




clear-host
#http://wfr791.pc.kiabi.fr/MBSDKService/MsgSDK.asmx?WSDL/GetMachineData
#$mycreds = Get-Credential -Credential "pc\dwuibail_adm"
#$ldWS = New-WebServiceProxy -uri http://wfr791.pc.kiabi.fr/MBSDKService/MsgSDK.asmx?WSDL -Credential $mycreds
$RepTEMP=$ENV:TEMP    
$fichierRapport = "$RepTEMP\RightClickEPMLogcomputer.log"

if (test-path $fichierRapport) { remove-item $fichierRapport -Recurse -force }

GetComputerDownloadFile $Mycomputer $fichierRapport
GetComputerTaskResult $Mycomputer "ALL" $fichierRapport
GetPolicySyncLog $Mycomputer $fichierRapport
GetPreferedserverDAT $Mycomputer $fichierRapport


if (test-path $fichierRapport) {start-Process $fichierRapport}
