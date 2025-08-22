$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
$DefaultUsername = "Compte"
$DefaultPassword = "Password"
$DefaultDomaine = "Domaine.local"
 
Set-ItemProperty $RegPath "AutoAdminLogon" -Value "1" -type String
Set-ItemProperty $RegPath "DefaultUsername" -Value "$DefaultUsername" -type String
Set-ItemProperty $RegPath "DefaultDomainName" -Value "$DefaultDomaine" -type String
Set-ItemProperty $RegPath "ForceAutoLogon" -Value "1" -type String
Set-ItemProperty $RegPath "DefaultPassword" -Value "$DefaultPassword" -type String
