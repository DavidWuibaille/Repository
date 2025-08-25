$ProductKey = (Get-WmiObject -Class SoftwareLicensingService).OA3xOriginalProductKey
cscript "c:\windows\system32\slmgr.vbs" -ipk $ProductKey
cscript "c:\windows\system32\slmgr.vbs" -ato
 
$ta = Get-CimInstance -ClassName SoftwareLicensingProduct -Filter "PartialProductKey IS NOT NULL" | Where-Object -Property Name -Like "Windows*"
$active      = $ta.LicenseStatus
$description = $ta.Description
write-host "--- $description ---"
if ($active -ne 1) {
  write-host "Activation Failed"
  $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}