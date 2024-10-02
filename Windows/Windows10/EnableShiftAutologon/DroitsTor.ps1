$path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\UserSwitch";
$account = New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList 'Administrators';
$acl = Get-Acl -Path $path;
$acl.SetOwner($account);
Set-Acl -Path $path -AclObject $acl;
