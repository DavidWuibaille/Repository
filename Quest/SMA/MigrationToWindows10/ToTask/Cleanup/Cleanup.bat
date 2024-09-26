if not exist c:\Drivers md c:\Drivers


Set cmdreg=reg
if defined PROCESSOR_ARCHITEW6432 Set cmdreg=%SystemRoot%\sysnative\reg.exe

:: Disk CLeanup LIght
if exist c:\temp rd c:\temp\* /S /Q
if exist c:\temp del c:\temp\*.* /S /Q
:: if exist d:\temp rd c:\temp\* /S /Q
:: if exist d:\temp del c:\temp\*.* /S /Q
Echo %time% : del c:\windows\temp
del c:\windows\temp\*.* /S /Q

Echo %time% : Clean temp folder>>c:\windows\temp\DiskCleanup.log


Echo %time% : Registry cleanmgr>>c:\windows\temp\DiskCleanup.log
%cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Active Setup Temp Folders" /v StateFlags1337 /t REG_DWORD /d 2 /f
:: %cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\BranchCache" /v StateFlags1337 /t REG_DWORD /d 2 /f
:: %cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Content Indexer Cleaner" /v StateFlags1337 /t REG_DWORD /d 2 /f
:: %cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\D3D Shader Cache" /v StateFlags1337 /t REG_DWORD /d 2 /f
:: %cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Delivery Optimization Files" /v StateFlags1337 /t REG_DWORD /d 2 /f
%cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Device Driver Packages" /v StateFlags1337 /t REG_DWORD /d 2 /f
%cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Diagnostic Data Viewer database files" /v StateFlags1337 /t REG_DWORD /d 2 /f
%cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Downloaded Program Files" /v StateFlags1337 /t REG_DWORD /d 2 /f
%cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Internet Cache Files" /v StateFlags1337 /t REG_DWORD /d 2 /f
:: %cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Microsoft Office Temp Files" /v StateFlags1337 /t REG_DWORD /d 2 /f
%cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Offline Pages Files" /v StateFlags1337 /t REG_DWORD /d 2 /f
:: %cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Old ChkDsk Files" /v StateFlags1337 /t REG_DWORD /d 2 /f
%cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Previous Installations" /v StateFlags1337 /t REG_DWORD /d 2 /f
%cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Recycle Bin" /v StateFlags1337 /t REG_DWORD /d 2 /f
:: %cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\RetailDemo Offline Content" /v StateFlags1337 /t REG_DWORD /d 2 /f
%cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Service Pack Cleanup" /v StateFlags1337 /t REG_DWORD /d 2 /f
%cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Setup Log Files" /v StateFlags1337 /t REG_DWORD /d 2 /f
%cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error memory dump files" /v StateFlags1337 /t REG_DWORD /d 2 /f
%cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error minidump files" /v StateFlags1337 /t REG_DWORD /d 2 /f
:: %cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Files" /v StateFlags1337 /t REG_DWORD /d 2 /f
%cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Setup Files" /v StateFlags1337 /t REG_DWORD /d 2 /f
:: %cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Sync Files" /v StateFlags1337 /t REG_DWORD /d 2 /f
%cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Thumbnail Cache" /v StateFlags1337 /t REG_DWORD /d 2 /f
%cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Update Cleanup" /v StateFlags1337 /t REG_DWORD /d 2 /f
%cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Upgrade Discarded Files" /v StateFlags1337 /t REG_DWORD /d 2 /f
:: %cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\User file versions" /v StateFlags1337 /t REG_DWORD /d 2 /f
:: %cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Defender" /v StateFlags1337 /t REG_DWORD /d 2 /f
%cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting Files" /v StateFlags1337 /t REG_DWORD /d 2 /f
%cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows ESD installation files" /v StateFlags1337 /t REG_DWORD /d 2 /f
%cmdreg% add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Upgrade Log Files" /v StateFlags1337 /t REG_DWORD /d 2 /f

Echo %time% : Start cleanmgr>>c:\windows\temp\DiskCleanup.log
cleanmgr.exe /SAGERUN:1337
Echo %time% : End cleanmgr>>c:\windows\temp\DiskCleanup.log

echo "Nettoyage temp users"
cd /d C:\Users
for /d %%z in (C:\Users\*) do (
	del %%z\AppData\Local\Temp\* /S /Q
	for /d %%y in (%%z\AppData\Local\Temp\*) do @rd /s /q "%%y"

	REM Nettoyage chrome
	del "%%z\AppData\Local\Google\Chrome\User Data\Default\*.tmp" /S /Q
	del "%%z\AppData\Local\Google\Chrome\User Data\Default\Cache\*" /S /Q
	del "%%z\AppData\Local\Google\Chrome\User Data\Default\Application Cache\Cache\*" /S /Q
	del "%%z\AppData\Local\Google\Chrome\User Data\Default\GPUCache\*" /S /Q
	del "%%z\AppData\Local\Google\Chrome\User Data\Default\Media Cache\*" /S /Q
	REM Nettoyage IE
	del "%%z\AppData\Local\Microsoft\Windows\Temporary Internet Files\*" /S /Q
	REM Test date ost et delete
	for %%v in (%%z\AppData\Local\Microsoft\Outlook\*.ost) do (
		echo %%v datant du %%~tv
	)
)

