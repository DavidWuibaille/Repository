Set cmdreg=reg
Set cmdpowershell=powershell
if defined PROCESSOR_ARCHITEW6432 Set cmdreg=%SystemRoot%\sysnative\reg.exe
if defined PROCESSOR_ARCHITEW6432 Set cmdpowershell=%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe

%cmdpowershell% -noprofile -command "Set-ExecutionPolicy bypass LocalMachine"
%cmdpowershell% -file "%~dp0Uninstall.ps1"

