
:CleanupLandesk
@echo off
del "C:\Program Files (x86)\LANDesk\LDClient\sdmcache\*.msu" /q
rd "C:\Program Files (x86)\LANDesk\LDClient\sdmcache\refinst\packageW7" /s /q
rd "C:\Program Files (x86)\LANDesk\LDClient\sdmcache\refinst\ToolsW7\" /s /q
rd "C:\Program Files (x86)\LANDesk\LDClient\sdmcache\refinst\SCX\packageW7" /s /q
rd "C:\Program Files (x86)\LANDesk\LDClient\sdmcache\refinst\SCX\ToolsW7\PnPDrivers" /s /q
rd "C:\Program Files (x86)\LANDesk\LDClient\sdmcache\refinst\KISS\packageW7" /s /q
rd "C:\Program Files (x86)\LANDesk\LDClient\sdmcache\refinst\KISS\ToolsW7\PnPDrivers" /s /q
rd "C:\Program Files (x86)\LANDesk\LDClient\sdmcache\refinst\Log\packageW7" /s /q
rd "C:\Program Files (x86)\LANDesk\LDClient\sdmcache\refinst\Log\ToolsW7\PnPDrivers" /s /q


:CleanupChrome
@echo on
cd /d C:\Users
for /d %%z in (C:\Users\*) do (
	del %%z\AppData\Local\Temp\* /S /Q
	for /d %%y in (%%z\AppData\Local\Temp\*) do @rd /s /q "%%y"
	del "%%z\AppData\Local\Google\Chrome\User Data\Default\*.tmp" /S /Q
	del "%%z\AppData\Local\Google\Chrome\User Data\Default\Cache\*" /S /Q
	del "%%z\AppData\Local\Google\Chrome\User Data\Default\Application Cache\Cache\*" /S /Q
	del "%%z\AppData\Local\Google\Chrome\User Data\Default\GPUCache\*" /S /Q
	del "%%z\AppData\Local\Google\Chrome\User Data\Default\Media Cache\*" /S /Q
	del "%%z\AppData\Local\Microsoft\Windows\Temporary Internet Files\*" /S /Q
)

