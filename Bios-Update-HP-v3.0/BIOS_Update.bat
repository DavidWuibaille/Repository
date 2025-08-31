:: Supprimer la tâche planifiée "BiosUpdateAtStartup"
SCHTASKS /DELETE /TN "BiosUpdateAtStartup" /F


:: Define log file
set LOGFILE=c:\windows\temp\HPBiosUpdate.log
echo [%DATE% %TIME%] --------- BIOS update started ----------->> "%LOGFILE%"

:: Find the "sp156628" directory in the script folder
if exist "%~dp0sp156628" (
    set BIOSFILE=sp156628
    goto :found
)

echo [%DATE% %TIME%] ERROR: Directory "sp156628" not found in %~dp0 >> "%LOGFILE%"
exit /B 1

:found
set Fullpath=%~dp0%BIOSFILE%
echo [%DATE% %TIME%] --------- Full path = %Fullpath% ----------->> "%LOGFILE%"

del "%Fullpath%\HpFirmwareUpdRec*.log" /F /Q
rmdir /s /q "%Fullpath%\ldcacheinfo"

:: Log possible exit codes
(
    echo [%DATE% %TIME%] 3010:SUCCESS:REBOOT=A restart is required to complete the install
    echo [%DATE% %TIME%] 1602:CANCEL:NOREBOOT=The install cannot complete due to a dependency
    echo [%DATE% %TIME%] 273:CANCEL:NOREBOOT=Flash did not update because update is same BIOS version
    echo [%DATE% %TIME%] 282:CANCEL:NOREBOOT=Flash did not update because update is an older BIOS version
) >> "%LOGFILE%"

:: Execute BIOS update
echo [%DATE% %TIME%] Running HpFirmwareUpdRec64.exe >> "%LOGFILE%"
start /wait "bios" "%Fullpath%\HpFirmwareUpdRec64.exe" -s -r -h -b -f"%Fullpath%"

:: Retrieve exit code
set exitcode=%ERRORLEVEL%
echo [%DATE% %TIME%] Exit code = %exitcode% >> "%LOGFILE%"

:: Handle exit codes
if %exitcode% EQU 3010 (
    echo [%DATE% %TIME%] BIOS update successful, restart required. >> "%LOGFILE%"
    echo [%DATE% %TIME%] Restarting in 30 seconds... >> "%LOGFILE%"
    shutdown /r /t 30 /c "BIOS update completed. Restarting in 30 seconds."
    exit /B 0
)
if %exitcode% EQU 1602 (
    echo [%DATE% %TIME%] Installation canceled: dependency issue. >> "%LOGFILE%"
    exit /B 1602
)
if %exitcode% EQU 273 (
    echo [%DATE% %TIME%] Update skipped: same BIOS version detected. >> "%LOGFILE%"
    exit /B 273
)
if %exitcode% EQU 282 (
    echo [%DATE% %TIME%] Update canceled: older BIOS version detected. >> "%LOGFILE%"
    exit /B 282
)
del "%Fullpath%\HpFirmwareUpdRec*.log" /F /Q
echo [%DATE% %TIME%] Unknown error: exit code %exitcode%. >> "%LOGFILE%"
exit /B 99
