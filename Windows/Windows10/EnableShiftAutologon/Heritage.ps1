$acl = get-acl HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\UserSwitch
$acl.SetAccessRuleProtection($true, $true)
set-acl HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\UserSwitch -AclObject $acl

