Param(
    [parameter(Mandatory=$true)][String]$Mycomputer
)

$remote = $Mycomputer

$ErrorActionPreference = "SilentlyContinue"
write-host "***** $remote *****"
write-host "c:\temp"
remove-item "\\$remote\c$\temp\*" -recurse
write-host "c:\windows\temp"
remove-item "\\$remote\c$\windows\temp\*" -recurse
write-host "sdmcache"
remove-item "\\$remote\c$\Program Files (x86)\LANDesk\LDClient\sdmcache\refinst\*" -recurse
write-host "corbeille"
remove-item "\\$remote\c$\$Recycle.Bin\*" -recurse
remove-item "\\$remote\c$\ldprovisioning" -recurse
remove-item "\\$remote\c$\PnPdrivers\*" -recurse
remove-item "\\$remote\c$\mount" -recurse
remove-item "\\$remote\c$\mountW10" -recurse
remove-item "\\$remote\c$\Exploit\Chipset" -recurse
remove-item "\\$remote\c$\Exploit\Intel_HD_Graphics_520_V20.19.15.4457" -recurse
remove-item "\\$remote\c$\Exploit\Video" -recurse
remove-item "\\$remote\c$\exploit\Temp" -recurse
remove-item "\\$remote\c$\Exploit\package" -recurse
remove-item "\\$remote\c$\$WINDOWS.~BT" -recurse
remove-item "\\$remote\d$\sdmcache\refinst\*" -recurse
remove-item "\\$remote\c$\MigrationW10\*" -recurse
remove-item "\\$remote\c$\Exploit\Package\*" -recurse



$Utilisateurs = Get-ChildItem -Path "\\$remote\c$\Users" -Directory -Force
Foreach($Utilisateur in $Utilisateurs) {
	write-host $Utilisateur.FullName
	remove-item "$Utilisateur.FullName\AppData\Local\Google\Chrome\User Data\Default\*.tmp" -recurse
	remove-item "$Utilisateur.FullName\AppData\Local\Google\Chrome\User Data\Default\Cache\*" -recurse
	remove-item "$Utilisateur.FullName\AppData\Local\Google\Chrome\User Data\Default\Application Cache\Cache\*" -recurse
	remove-item "$Utilisateur.FullName\AppData\Local\Google\Chrome\User Data\Default\GPUCache\*" -recurse
	remove-item "$Utilisateur.FullName\AppData\Local\Google\Chrome\User Data\Default\Media Cache\*" -recurse
	remove-item "$Utilisateur.FullName\AppData\Local\Google\Chrome\User Data\Default\*.tmp" -recurse
	remove-item "$Utilisateur.FullName\\AppData\Local\Temp\*" -recurse
}

$ErrorActionPreference = "Continue"