$path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\UserSwitch"
$acl = Get-Acl -Path $path
$rule = New-Object System.Security.AccessControl.RegistryAccessRule ("SYSTEM","FullControl","Deny")
$acl.SetAccessRule($rule)
$acl |Set-Acl -Path $path