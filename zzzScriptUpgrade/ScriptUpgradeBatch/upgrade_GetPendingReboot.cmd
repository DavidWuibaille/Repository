:InitSynative
@echo off
Set cmdreg=reg
if defined PROCESSOR_ARCHITEW6432 Set cmdreg=%SystemRoot%\sysnative\reg.exe

:GetPendingReboot
%cmdreg% query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v PendingFileRenameOperations
if %ERRORLEVEL% EQU 0 goto PassReboot
%cmdreg% query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing" /v RebootPending
if %ERRORLEVEL% EQU 0 goto PassReboot
%cmdreg% query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v RebootRequired
if %ERRORLEVEL% EQU 0 goto PassReboot
%cmdreg% query "HKLM\SOFTWARE\Wow6432Node\landesk\managementsuite\WinClient\VulscanReboot"
if %ERRORLEVEL% EQU 0 goto PassReboot

:GetWindowsold
::If exist "c:\Windows.old" goto PassWindowsold

Goto OKcontinue

:PassReboot
echo ********** PendingReboot ********************************
timeout 30
Exit /B 1000

:PassWindowsold
echo ********** Windowsold ********************************
timeout 30
Exit /B 1002

:OKcontinue
echo No Pending Reboot
Exit /B 0