#----------------------------------------------------------------------------
# Configuration stuff
#----------------------------------------------------------------------------
$ServerName = "LocalHost"
$UseSecureConnection = $False
$port = 8530
$VerbosePreference = "Continue"
$ErrorActionPreference = "Stop"
$displayReport = $true
$logFolder = "C:\Temp"
$maxLogs = 366
$nbLicenseAccepted = 0
$nbUpdatesDeclined = 0
$nbUpdatesGlobalApproved = 0
$nbUpdatesWaitingGlobalApproved = 0


#----------------------------------------------------------------------------
# DO NOT MODIFY BELOW
#----------------------------------------------------------------------------
$CSVfile = $PSScriptRoot+"\export.csv"
write-output "Titre;Group" | out-file -append -encoding utf8 $CSVfile

If (-Not(Test-Path $logFolder)){ MD $logFolder | Out-Null }
$logFile = $logFolder + "\" + (Get-Date -format "yyyyMMdd-HHmmss").ToString() + ".log"
Start-Transcript -Path $logFile -Force | Out-Null

# Load required assemblies
[void][reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration")
$wsusServer        = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer($ServerName, $UseSecureConnection, $port)
$subscription      = $wsusServer.GetSubscription()
$wsusServerConfig  = $wsusServer.GetConfiguration()
$targetGroups      = $wsusServer.GetComputerTargetGroups()
$updates           = $wsusServer.GetUpdates()


$workingUpdates = $updates | Where { -Not $_.IsDeclined}
Foreach ($update in $workingUpdates){
	$Titrepatch = $update.Title
	#Write-Verbose ("Title: " + $update.Title) 
	
	If ($update.RequiresLicenseAgreementAcceptance)                     { $update.AcceptLicenseAgreement() } # Accept license agreement if required
	If ($update.Title -Match "Windows Malicious Software Removal Tool") { $update.Decline() }
	

	$approvals = $update.GetUpdateApprovals()
	Foreach ($approval in $approvals){
		$PatchToGroup = ""
		Foreach ($targetGroup in $targetGroups){
			$PatchGroupeID = $approval.ComputerTargetGroupId
			$GroupeID      = $targetGroup.Id
			$GroupeName    = $targetGroup.Name
			if ($PatchGroupeID -eq $GroupeID) { 
				$PatchToGroup = $GroupeName 
				
			}
		}
		$PatchToGroup = "$Titrepatch"+";"+$PatchToGroup
		write-output $PatchToGroup | out-file -append -encoding utf8 $CSVfile
		
	}
}



# Remove old log files
$limit = (Get-Date).AddDays(-$maxLogs)
Get-ChildItem -Path "${logFolder}\*.log" -Force | Where-Object { $_.CreationTime -lt $limit } | Foreach { Remove-Item $_ -Force }
Stop-Transcript

