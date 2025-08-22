# List of Applications to Remove
$AppPackages  = @()
$AppPackages += 'Microsoft.3DBuilder'
$AppPackages += 'Microsoft.BingWeather'
$AppPackages += 'Microsoft.DesktopAppIinstaller'
$AppPackages += 'Microsoft.Getstarted'
$AppPackages += 'Microsoft.Messaging'
$AppPackages += 'Microsoft.MicrosoftOfficeHub'
$AppPackages += 'Microsoft.MicrosoftSolitaireCollection'
$AppPackages += 'Microsoft.MicrosoftStickyNotes'
$AppPackages += 'Microsoft.Office.OneNote'
$AppPackages += 'Microsoft.Office.OneConnect'
$AppPackages += 'Microsoft.People'
$AppPackages += 'Microsoft.SkypeApp'
$AppPackages += 'Microsoft.StorePurchaseApp'
$AppPackages += 'Microsoft.Windows.Photos'
$AppPackages += 'WindowsAlarms'
$AppPackages += 'Microsoft.WindowsCalculator'
$AppPackages += 'Microsoft.WindowsCamera'
$AppPackages += 'microsoft.windowscommunicationsapps'
$AppPackages += 'Microsoft.WindowsFeedbackHub'
$AppPackages += 'Microsoft.WindowsMaps'
$AppPackages += 'Microsoft.WindowsPhone'
$AppPackages += 'Microsoft.WindowsSoundRecorder'
$AppPackages += 'Microsoft.WindowsStore'
$AppPackages += 'Microsoft.XboxApp'
$AppPackages += 'Microsoft.XboxIdentityProvider'
$AppPackages += 'Microsoft.ZuneMusic'
$AppPackages += 'Microsoft.ZuneVideo'


foreach ($App In $AppPackages) {

    Write-Host "Removing Package : $App"
	
	$Package = Get-AppxPackage | Where-Object {$_.Name -eq $App}
    If ($Package -ne $null) {
        Remove-AppxPackage -Package $Package.PackageFullName -ErrorAction SilentlyContinue
    }

	$Package = Get-AppxPackage -Allusers| Where-Object {$_.Name -eq $App}
    If ($Package -ne $null) {
        Remove-AppxPackage -Package $Package.PackageFullName -ErrorAction SilentlyContinue
    }
	
    $ProvisionedPackage = Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq $App}
        If ($ProvisionedPackage -ne $null) {
        Remove-AppxProvisionedPackage -Online -PackageName $ProvisionedPackage.PackageName -ErrorAction SilentlyContinue
    }

}