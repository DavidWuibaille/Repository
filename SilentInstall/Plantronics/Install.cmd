@echo off

REM Initialisation des variables vardate et vartime
set vardate=%DATE:/=% 
set vartime=%time:~0,2%%time:~3,2%

REM Verification de la présence du repertoire C:\exploit et C:\exploit\log
If not exist "C:\exploit" md "C:\exploit"
If not exist "C:\exploit\log" md "C:\exploit\log"

Set cmdreg=reg
Set cmdpowershell=powershell
if defined PROCESSOR_ARCHITEW6432 Set cmdreg=%SystemRoot%\sysnative\reg.exe
if defined PROCESSOR_ARCHITEW6432 Set cmdpowershell=%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe

%cmdpowershell% -noprofile -command "Set-ExecutionPolicy bypass LocalMachine"
%cmdpowershell% -file "%~dp0Uninstall.ps1"

REM Installation de l'application
"%~dp0PlantronicsHubInstaller.exe" /install /quiet /norestart /log "C:\exploit\log\INSTALL_PlantronicsHub_3.24.53463_%vardate%_%vartime%.log"

goto fin

:fin