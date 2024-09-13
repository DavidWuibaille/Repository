Set cmdwinsat=Winsat
Set cmdpowershell=powershell
Set cmdpowercfg=powercfg
if defined PROCESSOR_ARCHITEW6432 Set cmdwinsat=%SystemRoot%\Sysnative\cmd.exe /c Winsat
if defined PROCESSOR_ARCHITEW6432 Set cmdpowershell=%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe
if defined PROCESSOR_ARCHITEW6432 Set cmdpowercfg=%SystemRoot%\Sysnative\cmd.exe /c powercfg


copy "%~dp0CustWin.cmd" c:\windows\CustWin.cmd /Y
regedit /s "%~dp0activeSetup.reg"
