$logFolder = "c:\exploit\logs"
$maxLogs = 60
 
$SyncApprovals = @(
 
    @{"Source" = "TESTERS"  ; "Target" = "PILOT"  ; "MinDays" = 5},
    @{"Source" = "PILOT"  ; "Target" = "PROD"    ; "MinDays" = 5}
)
 
# ----------------- Log Files ----------------------
If (!(Test-Path $logFolder)) { New-Item -Path "$logFolder" -ItemType Directory }
$logFile = $logFolder + "\WSUS-ManageApprovals" + (Get-Date -format "yyyyMMdd-HHmmss").ToString() + ".log"
Start-Transcript -Path $logFile -Force | Out-Null
 
# ----------------- Connect WSUS server ------------
[reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") | Out-Null
$wsusServer       = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer()
$subscription     = $wsusServer.GetSubscription()
$wsusServerConfig = $wsusServer.GetConfiguration()
$targetGroups     = $wsusServer.GetComputerTargetGroups()
$updates          = $wsusServer.GetUpdates()
 
# ----------------- Synchronize --------------------
$subscription.StartSynchronization()
 
# ----------------- Manage KB ----------------------
$workingUpdates = $updates | Where { -Not $_.IsDeclined}
Foreach ($update in $workingUpdates){
  If ($update.Title -Match "Windows Malicious Software Removal Tool") { $update.Decline()                } # Decline "Windows Malicious Software Removal Tool" Update automatically
  If ($update.RequiresLicenseAgreementAcceptance)                     { $update.AcceptLicenseAgreement() } # Accept license agreement if required
}
 
# ----------------- Approve KB ------------------
write-host "********** Approve KB **********"
$workingUpdates = $updates | Where { -Not $_.IsDeclined}
Foreach ($update in $workingUpdates){
  $approvals = $update.GetUpdateApprovals()
  Foreach ($syncApproval in $SyncApprovals){
    $sourceGroup    = $targetGroups | Where { $_.Name                  -eq $syncApproval.Source }
    $sourceApproval = $approvals    | Where { $_.ComputerTargetGroupId -eq $sourceGroup.ID      }
 
        If ($($sourceApproval.Action) -eq "Install"){
      $LastChangeKB = (New-TimeSpan -start $sourceApproval.GoLiveTime -End (Get-Date)).Days
        If($LastChangeKB -ge $syncApproval.MinDays) {
 
            $targetGroup    = $targetGroups | Where { $_.Name                  -eq $syncApproval.Target }
            $targetApproval = $approvals    | Where { $_.ComputerTargetGroupId -eq $targetGroup.ID }
          If ($($targetApproval.Action) -ne "Install") {
                    Write-host "Enable : $($syncApproval.Target) => $($update.Title) - $LastChangeKB days"
            $update.Approve("Install", $targetGroup )  | Out-Null
          }
        }
        }
  }
}
write-host ""
 
 
# ------------ Disabled KB
write-host "********** Disable Superseded **********"
$workingUpdates = $updates | Where { -Not $_.IsDeclined} | Where { $_.IsSuperseded}
Foreach ($update in $workingUpdates){
  write-host "$($update.Title)"
  Foreach ($Supersede in $update.GetRelatedUpdates([Microsoft.UpdateServices.Administration.UpdateRelationship]::UpdatesThatSupersedeThisUpdate)){
    write-host "----- Replace By : $($Supersede.Title)"
    $approvals = $Supersede.GetUpdateApprovals()
 
    Foreach ($approval in $approvals) {
      Foreach ($targetGroup in $targetGroups){
        If (( $targetGroup.Id -eq $approval.ComputerTargetGroupId ) -and ($($approval.Action) -eq "Install")) {
          write-host "---------- $($targetGroup.Name)"
          if ($($targetGroup.Name) -like "*GLOBAL*ODD*") {
            Write-host "---------- Decline : $($update.Title)"
            $update.Decline()
 
          }
        }
      }
    }
  }
 
}
write-host ""
 
 
# ----------------- Cleanup Server ----------------
write-host "********** Cleanup WSUS **********"
$cleanupInterface = $wsusServer.GetCleanupManager();
$cleanupScope = new-object 'Microsoft.UpdateServices.Administration.CleanupScope';
$cleanupScope.DeclineSupersededUpdates = $True;
$cleanupScope.DeclineExpiredUpdates = $True;
$cleanupScope.CleanupObsoleteComputers = $True;
$cleanupScope.CleanupObsoleteUpdates = $True;
$cleanupScope.CompressUpdates = $True;
$cleanupScope.CleanupUnneededContentFiles = $True;
$cleanupInterface.PerformCleanup($cleanupScope)
write-host ""