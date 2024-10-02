$acl = get-acl HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\UserSwitch
$acl.PurgeAccessRules([System.Security.Principal.NTAccount] "SYSTEM")
set-acl HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\UserSwitch -AclObject $acl