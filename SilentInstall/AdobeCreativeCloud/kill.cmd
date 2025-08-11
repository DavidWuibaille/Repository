Set cmdpowershell=powershell
if defined PROCESSOR_ARCHITEW6432 Set cmdpowershell=%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe

%cmdpowershell% -command stop-process -Name "*adobe*" -Force
