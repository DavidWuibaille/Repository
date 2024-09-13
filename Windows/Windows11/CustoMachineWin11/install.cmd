Set cmdwinsat=Winsat
Set cmdpowershell=powershell
Set cmdpowercfg=powercfg
if defined PROCESSOR_ARCHITEW6432 Set cmdwinsat=%SystemRoot%\Sysnative\cmd.exe /c Winsat
if defined PROCESSOR_ARCHITEW6432 Set cmdpowershell=%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe
if defined PROCESSOR_ARCHITEW6432 Set cmdpowercfg=%SystemRoot%\Sysnative\cmd.exe /c powercfg



:: ********** Gestion des AppxPackage **********
%cmdpowershell% -command Get-AppxProvisionedPackage -online ^| where-object {$_.packageName -like '*GamingApp*'} ^| remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
%cmdpowershell% -command Get-AppxProvisionedPackage -online ^| where-object {$_.packageName -like '*GetHelp*'} ^| remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
%cmdpowershell% -command Get-AppxProvisionedPackage -online ^| where-object {$_.packageName -like '*Getstarted*'} ^| remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
%cmdpowershell% -command Get-AppxProvisionedPackage -online ^| where-object {$_.packageName -like '*MicrosoftSolitaireCollection*'} ^| remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
%cmdpowershell% -command Get-AppxProvisionedPackage -online ^| where-object {$_.packageName -like '*MicrosoftOfficeHub*'} ^| remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
%cmdpowershell% -command Get-AppxProvisionedPackage -online ^| where-object {$_.packageName -like '*People*'} ^| remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
%cmdpowershell% -command Get-AppxProvisionedPackage -online ^| where-object {$_.packageName -like '*WindowsFeedbackHub*'} ^| remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
%cmdpowershell% -command Get-AppxProvisionedPackage -online ^| where-object {$_.packageName -like '*Xbox*'} ^| remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
%cmdpowershell% -command Get-AppxProvisionedPackage -online ^| where-object {$_.packageName -like '*Zune*'} ^| remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
%cmdpowershell% -command Get-AppxProvisionedPackage -online ^| where-object {$_.packageName -like '*Bing*'} ^| Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue


:: Performance (obligatoire pour les portables)
%cmdwinsat% formal

:: Manage account
wmic path Win32_UserAccount WHERE Name="administrator" set PasswordExpires=false
wmic path Win32_UserAccount WHERE Name="administrateur" set PasswordExpires=false


:: ********** gestion du start Menu ************
xcopy "%~dp0start.bin" "c:\Users\Default\AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState\" /y
