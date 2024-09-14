Param(
    [parameter(Mandatory=$true)][String]$Mycomputer
)

function Log {
    param(
        [string] $ficherLog,
		[string] $ValeurLog
    )
    #ADD-content $ficherLog -value $ValeurLog
	$ValeurLog | Out-File $ficherLog -Append

    write-host $ValeurLog
}

function GetHistoriquePC {
    param (
        $mycomputer,
        $logfile
    )

    Log $logfile "************** HistoriquePC ($mycomputer) **************"    
    if (test-path "\\$mycomputer\c$") {
        $Records = Get-WmiObject -class win32_ReliabilityRecords -computername $mycomputer
		    foreach ($element in $Records) {
            $Date = $element.ConvertToDateTime($element.TimeGenerated)
            
            Log $logfile $Date
            Log $logfile $element.ProductName
            Log $logfile $element.SourceName
            Log $logfile $element.User
            Log $logfile $element.Message
            Log $logfile "----------------------------------"
            
        }
    } Else {
        Log $logfile "ERROR"
    }
}

$RepTEMP=$ENV:TEMP    
$fichierRapport = "$RepTEMP\RightClickEPMHitoPC.log"

if (test-path $fichierRapport) { remove-item $fichierRapport -Recurse -force }

write-host $Mycomputer
GetHistoriquePC $Mycomputer $fichierRapport

if (test-path $fichierRapport) {start-Process $fichierRapport}
