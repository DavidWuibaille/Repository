Set cmddism=dism
Set cmdwusa=wusa
Set cmdpowershell=powershell
Set cmdreg=reg
Set cmdpowercfg=powercfg
Set cmdcscript=cscript
if defined PROCESSOR_ARCHITEW6432 Set cmddism=%SystemRoot%\Sysnative\cmd.exe /c Dism
if defined PROCESSOR_ARCHITEW6432 Set cmdpowershell=%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe
if defined PROCESSOR_ARCHITEW6432 Set cmdwusa=%SystemRoot%\sysnative\wusa.exe
if defined PROCESSOR_ARCHITEW6432 Set cmdreg=%SystemRoot%\sysnative\reg.exe
if defined PROCESSOR_ARCHITEW6432 Set cmdpowercfg=%SystemRoot%\Sysnative\cmd.exe /c powercfg
if defined PROCESSOR_ARCHITEW6432 Set cmdcscript=%SystemRoot%\Sysnative\cscript.exe

xcopy "%~dp0Modules\DellBIOSProvider"   "C:\Program Files\WindowsPowerShell\Modules\DellBIOSProvider\" /S /Y /E
%cmdpowershell% -executionPolicy bypass -file "%~dp0EnableBitlocker.ps1"
