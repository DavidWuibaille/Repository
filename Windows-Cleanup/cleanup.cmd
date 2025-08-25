Set cmddism=dism
Set cmdreg=reg
if defined PROCESSOR_ARCHITEW6432 Set cmddism=%SystemRoot%\Sysnative\cmd.exe /c Dism
if defined PROCESSOR_ARCHITEW6432 Set cmdreg=%SystemRoot%\sysnative\reg.exe
 
ver | find "10.0" > nul
if %ERRORLEVEL% == 0 goto Windows10
Goto NoWindows10
 
:Windows10
%cmddism% /online /Cleanup-Image /analyzecomponentstore
%cmddism% /online /Cleanup-Image /StartComponentCleanup /ResetBase
:NoWindows10
 
del c:\windows\temp\*.* /S /Q
 
%cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Active Setup Temp Folders" /v StateFlags1234 /t REG_DWORD /d 2 /f
:: %cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\BranchCache" /v StateFlags1234 /t REG_DWORD /d 2 /f
:: %cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Content Indexer Cleaner" /v StateFlags1234 /t REG_DWORD /d 2 /f
:: %cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\D3D Shader Cache" /v StateFlags1234 /t REG_DWORD /d 2 /f
:: %cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Delivery Optimization Files" /v StateFlags1234 /t REG_DWORD /d 2 /f
%cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Device Driver Packages" /v StateFlags1234 /t REG_DWORD /d 2 /f
%cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Diagnostic Data Viewer database files" /v StateFlags1234 /t REG_DWORD /d 2 /f
%cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Downloaded Program Files" /v StateFlags1234 /t REG_DWORD /d 2 /f
%cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Internet Cache Files" /v StateFlags1234 /t REG_DWORD /d 2 /f
:: %cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Microsoft Office Temp Files" /v StateFlags1234 /t REG_DWORD /d 2 /f
%cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Offline Pages Files" /v StateFlags1234 /t REG_DWORD /d 2 /f
:: %cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Old ChkDsk Files" /v StateFlags1234 /t REG_DWORD /d 2 /f
%cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Previous Installations" /v StateFlags1234 /t REG_DWORD /d 2 /f
%cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Recycle Bin" /v StateFlags1234 /t REG_DWORD /d 2 /f
:: %cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\RetailDemo Offline Content" /v StateFlags1234 /t REG_DWORD /d 2 /f
%cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Service Pack Cleanup" /v StateFlags1234 /t REG_DWORD /d 2 /f
%cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Setup Log Files" /v StateFlags1234 /t REG_DWORD /d 2 /f
%cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error memory dump files" /v StateFlags1234 /t REG_DWORD /d 2 /f
%cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error minidump files" /v StateFlags1234 /t REG_DWORD /d 2 /f
:: %cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Files" /v StateFlags1234 /t REG_DWORD /d 2 /f
%cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Setup Files" /v StateFlags1234 /t REG_DWORD /d 2 /f
:: %cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Sync Files" /v StateFlags1234 /t REG_DWORD /d 2 /f
%cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Thumbnail Cache" /v StateFlags1234 /t REG_DWORD /d 2 /f
%cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Update Cleanup" /v StateFlags1234 /t REG_DWORD /d 2 /f
%cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Upgrade Discarded Files" /v StateFlags1234 /t REG_DWORD /d 2 /f
:: %cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\User file versions" /v StateFlags1234 /t REG_DWORD /d 2 /f
:: %cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Defender" /v StateFlags1234 /t REG_DWORD /d 2 /f
%cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting Files" /v StateFlags1234 /t REG_DWORD /d 2 /f
%cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows ESD installation files" /v StateFlags1234 /t REG_DWORD /d 2 /f
%cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Upgrade Log Files" /v StateFlags1234 /t REG_DWORD /d 2 /f
 
cleanmgr.exe /SAGERUN:1234