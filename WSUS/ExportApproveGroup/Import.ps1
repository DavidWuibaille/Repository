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
$ListPatchs = Import-Csv $CSVfile -Delimiter ";"

Write-host "-------------- $CSVfile -----------------------"

# Load required assemblies
[void][reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration")
$wsusServer        = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer($ServerName, $UseSecureConnection, $port)
$subscription      = $wsusServer.GetSubscription()
$wsusServerConfig  = $wsusServer.GetConfiguration()
$targetGroups      = $wsusServer.GetComputerTargetGroups()
$updates           = $wsusServer.GetUpdates()

$install = [Microsoft.UpdateServices.Administration.UpdateApprovalAction]::Install


foreach ($ListPatch in $ListPatchs) {
	$CSVtitre = $ListPatch.Titre
	$CSVgroup = $ListPatch.Group
	
	Foreach ($update in $updates) {

		$Titrepatch = $update.Title
		If ($Titrepatch -eq $CSVtitre) {

			If ($update.RequiresLicenseAgreementAcceptance)                     { $update.AcceptLicenseAgreement() } # Accept license agreement if required
			Foreach ($targetGroup in $targetGroups){
				$GroupeID      = $targetGroup.Id
				$GroupeName    = $targetGroup.Name
				if ($CSVgroup -eq $GroupeName) { 
					Write-host "$CSVtitre > $CSVgroup"
					$approvals  = $update.GetUpdateApprovals()
					$group = $wsusServer.GetComputerTargetGroups() | ? {$_.Name -eq $GroupeName}
					$update.Approve($install,$group)
					
				}
			}
			
			
			
		}


	}
		
}
	
	
