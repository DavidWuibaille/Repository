Set cmdreg=reg
Set cmdpowershell=powershell
Set cmdpowercfg=powercfg
if defined PROCESSOR_ARCHITEW6432 Set cmdreg=%SystemRoot%\sysnative\reg.exe
if defined PROCESSOR_ARCHITEW6432 Set cmdpowershell=%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe
if defined PROCESSOR_ARCHITEW6432 Set cmdpowercfg=%SystemRoot%\Sysnative\cmd.exe /c powercfg

if exist c:\exploit\vbooton.flg goto suite
%cmdreg% delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "AutoAdminLogon" /f
%cmdreg% delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "DefaultPassword" /f
%cmdreg% delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "AutoLogonCount" /f
%cmdreg% delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "ForceAutoLogon" /f
:suite

start c:\windows\system32\shutdown.exe /r /t 60 /c "Final restart"

if exist c:\users\administrateur %cmdnet% user administrateur /active:no
if exist c:\users\administrator %cmdnet% user administrator /active:no

