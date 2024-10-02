Set cmdreg=reg
Set cmdpowershell=powershell
Set cmdpowercfg=powercfg
if defined PROCESSOR_ARCHITEW6432 Set cmdreg=%SystemRoot%\sysnative\reg.exe
if defined PROCESSOR_ARCHITEW6432 Set cmdpowershell=%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe
if defined PROCESSOR_ARCHITEW6432 Set cmdpowercfg=%SystemRoot%\Sysnative\cmd.exe /c powercfg

%cmdpowershell% -noprofile -command "Set-ExecutionPolicy bypass LocalMachine"

:: force un dns pour fonctionner sur mon LAB
%cmdpowershell% -file "%~dp0SetDNS.ps1"

"%~dp0netdom.exe" JOIN %computername% /Domain:leblogosd.lan /UserD:david /PasswordD:Motdepasse1

exit /B 0
