Set cmdwinsat=Winsat
Set cmdpowershell=powershell
Set cmdpowercfg=powercfg
Set cmdreg=reg
if defined PROCESSOR_ARCHITEW6432 Set cmdwinsat=%SystemRoot%\Sysnative\cmd.exe /c Winsat
if defined PROCESSOR_ARCHITEW6432 Set cmdpowershell=%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe
if defined PROCESSOR_ARCHITEW6432 Set cmdpowercfg=%SystemRoot%\Sysnative\cmd.exe /c powercfg
if defined PROCESSOR_ARCHITEW6432 Set cmdreg=%SystemRoot%\sysnative\reg.exe


:: menu demarrer a gauche
%cmdreg% add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAl /t REG_DWORD /d 0 /f

:: desactiver recherche bing dans le menu demarrer
%cmdreg% add HKCU\Software\Policies\Microsoft\Windows\Explorer /v DisableSearchBoxSuggestions /t reg_dword /d 1 /f

:: desactiver chat taskbat
%cmdreg% add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v TaskbarMn /t reg_dword /d 0 /f

:: desactiver widget taskbat
%cmdreg% add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v TaskbarDa /t reg_dword /d 0 /f

:: desactiver Multi Bureau
%cmdreg% add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v ShowTaskViewButton /t reg_dword /d 0 /f

:: pas d'affichage du store dans la barre des taches
%cmdreg% add HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer /v NoPinningStoreToTaskbar /t reg_dword /d 1 /f


:: ********** Gestion des AppxPackage **********
%cmdpowershell% -command Get-AppxPackage ^| where-object {$_.Name -like '*Xbox*'} ^| remove-AppxPackage -ErrorAction SilentlyContinue
%cmdpowershell% -command Get-AppxPackage ^| where-object {$_.Name -like '*Zune*'} ^| remove-AppxPackage -ErrorAction SilentlyContinue
%cmdpowershell% -command Get-AppxPackage ^| where-object {$_.Name -like '*Teams*'} ^| remove-AppxPackage -ErrorAction SilentlyContinue
%cmdpowershell% -command Get-AppxPackage ^| where-object {$_.Name -like '*Getstarted*'} ^| remove-AppxPackage -ErrorAction SilentlyContinue
%cmdpowershell% -command Get-AppxPackage ^| where-object {$_.Name -like '*GetHelp*'} ^| remove-AppxPackage -ErrorAction SilentlyContinue
%cmdpowershell% -command Get-AppxPackage ^| where-object {$_.Name -like '*WindowsFeedbackHub*'} ^| remove-AppxPackage -ErrorAction SilentlyContinue
%cmdpowershell% -command Get-AppxPackage ^| where-object {$_.Name -like '*GamingApp*'} ^| remove-AppxPackage -ErrorAction SilentlyContinue
