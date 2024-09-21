
$Today = Get-Date
$DateUTC = $Today.ToUniversalTime()
$DateUTCFormatted = $DateUTC.ToString('yyyy-MM-dd HH:mm:ss')

$UpdateCollection = New-Object -ComObject Microsoft.Update.UpdateColl
$Searcher         = New-Object -ComObject Microsoft.Update.Searcher
$Session          = New-Object -ComObject Microsoft.Update.Session

# ---------- Search available updates
Write-Host
Write-Host "------Initialising and Checking for Applicable Updates. Please wait ..." -ForeGroundColor "Yellow"
$Result = $Searcher.Search("IsInstalled=0 and Type='Software' and IsHidden=0")
If ($Result.Updates.Count -ne 0) {
	Write-Host "------Preparing List of Applicable Updates For This Computer ..." -ForeGroundColor "Yellow"
	For ($Counter = 0; $Counter -LT $Result.Updates.Count; $Counter++) {
		$DisplayCount = $Counter + 1
			$Update = $Result.Updates.Item($Counter)
		$UpdateTitle = $Update.Title
		Write-Host "-------------$DisplayCount : $UpdateTitle"
	}
# ---------- Download available updates
	$Counter = 0
	$DisplayCount = 0
	Write-Host "------Initialising Download of Applicable Updates ..." -ForegroundColor "Yellow"
	$Downloader  = $Session.CreateUpdateDownloader()
	$UpdatesList = $Result.Updates
	For ($Counter = 0; $Counter -lt $Result.Updates.Count; $Counter++) {
		$UpdateCollection.Add($UpdatesList.Item($Counter)) | Out-Null
		$ShowThis = $UpdatesList.Item($Counter).Title
		$DisplayCount = $Counter + 1
		Write-Host "-------------$DisplayCount : $ShowThis"
		$Downloader.Updates = $UpdateCollection
		$Track = $Downloader.Download()
		If (($Track.HResult -eq 0) -AND ($Track.ResultCode -eq 2)) {
			Write-Host "-------------Download Status: SUCCESS"
		} Else {
			Write-Host "-------------Download Status: FAILED With Error -- $Error()"
		}
	}
	
	
# ---------- Install downloaded updates
	$Counter = 0
	$DisplayCount = 0
	Write-Host "------Starting Installation of Downloaded Updates ..." -ForegroundColor "Yellow"
	$Installer = New-Object -ComObject Microsoft.Update.Installer
	For ($Counter = 0; $Counter -lt $UpdateCollection.Count; $Counter++) {
		$Track = $Null
		$DisplayCount = $Counter + 1
		$WriteThis = $UpdateCollection.Item($Counter).Title
		write-host "-------------$DisplayCount : $WriteThis"
		$Installer.Updates = $UpdateCollection
		Try {
			$Track = $Installer.Install()
			write-host "-------------Update Installation Status: SUCCESS"
		}
		Catch {
			[System.Exception]
			write-host "-------------Update Installation Status: FAILED With Error -- $Error()"
		}
	}
	Restart-Service -Name 'wuauserv' -Force #refresh windows patch list 
	Restart-Computer
} Else {
	Write-Host "-------------There are no applicable updates for this computer."
}


