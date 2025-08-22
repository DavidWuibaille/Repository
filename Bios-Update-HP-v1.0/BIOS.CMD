REM Initialisation des variables vardate et vartime
for /F "skip=1 delims=" %%F in ('
 wmic PATH Win32_LocalTime GET Day^,Month^,Year /FORMAT:TABLE
') do (
 for /F "tokens=1-3" %%L in ("%%F") do (
 set CurrDay=0%%L
 set CurrMonth=0%%M
 set CurrYear=%%N
 )
)
set CurrDay=%CurrDay:~-2%
set CurrMonth=%CurrMonth:~-2%
set vardate=%CurrYear%%CurrMonth%%CurrDay%
if "%time:~0,1%"==" " (
set vartime=0%time:~1,1%%time:~3,2%
) else (
set vartime=%time:~0,2%%time:~3,2%
)

Set cmdreg=reg
Set cmdPnputil=c:\windows\system32\pnputil.exe
Set cmdpowershell=powershell
if defined PROCESSOR_ARCHITEW6432 Set cmdreg=%SystemRoot%\sysnative\reg.exe
if defined PROCESSOR_ARCHITEW6432 Set cmdPnputil=%SystemRoot%\Sysnative\cmd.exe /c c:\windows\system32\pnputil.exe
if defined PROCESSOR_ARCHITEW6432 Set cmdpowershell=%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe

echo ---------Bios update ----------->>C:\pnpDrivers\BIOS.log
for /f "delims=" %%D in ('dir /a:d /b %~dp0') do set BIOSFILE=%%D
echo %BIOSFILE%
set Fullpath=%~dp0%BIOSFILE%
echo ---------Fullpath = %Fullpath% ----------->>C:\pnpDrivers\BIOS.log

cd "%Fullpath%"
del "%Fullpath%\HpFirmwareUpdRec.log" /F /Q

echo 3010:SUCCESS:REBOOT=A restart is required to complete the install>>C:\pnpDrivers\BIOS.log
echo 1602:CANCEL:NOREBOOT=The install is cannot complete due to a dependency>>C:\pnpDrivers\BIOS.log
echo 273:CANCEL:NOREBOOT=Flash did not update because update is same BIOS version>>C:\pnpDrivers\BIOS.log
echo 282:CANCEL:NOREBOOT=Flash did not update because update is an older BIOS version>>C:\pnpDrivers\BIOS.log

if EXIST "%Fullpath%\HpFirmwareUpdRec.exe" echo HpFirmwareUpdRec.exe>>C:\pnpDrivers\BIOS.log
if EXIST "%Fullpath%\HpFirmwareUpdRec.exe" start /wait "BIOS" "%Fullpath%\HpFirmwareUpdRec.exe" -s -r -h -b -f"%Fullpath%
if EXIST "%Fullpath%\HPBIOSUPDREC.exe" echo HPBIOSUPDREC.exe>>C:\pnpDrivers\BIOS.log
if EXIST "%Fullpath%\HPBIOSUPDREC.exe" start /wait "BIOS" "%Fullpath%\HPBIOSUPDREC.exe" -s -b -r -a
if EXIST "%Fullpath%\install.cmd" echo %Fullpath%\install.cmd>>C:\pnpDrivers\BIOS.log
if EXIST "%Fullpath%\install.cmd" Call "%Fullpath%\install.cmd"

set codesortie=%ERRORLEVEL%
echo %codesortie%>>C:\pnpDrivers\BIOS.log
if %codesortie% EQU 3010 exit /B 0
