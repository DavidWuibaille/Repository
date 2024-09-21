# Cleanup Server
$ServerName = "LocalHost"
$UseSecureConnection = $False
$port = 8530
[void][reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration")
$wsusServer = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer($ServerName, $UseSecureConnection, $port)
$cleanupInterface = $wsusServer.GetCleanupManager(); 
$cleanupScope = new-object 'Microsoft.UpdateServices.Administration.CleanupScope'; 
$cleanupScope.DeclineSupersededUpdates = $True; 
$cleanupScope.DeclineExpiredUpdates = $True; 
$cleanupScope.CleanupObsoleteComputers = $True; 
$cleanupScope.CleanupObsoleteUpdates = $True; 
$cleanupScope.CompressUpdates = $True; 
$cleanupScope.CleanupUnneededContentFiles = $True;
$cleanupInterface.PerformCleanup($cleanupScope)
