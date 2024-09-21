cscript "%~dp0CheckMsiexec.vbs"

if "%PROCESSOR_ARCHITECTURE%"=="x86" goto archix86

:archix64

Call "%~dp0installx64.bat"

goto fin

:archix86

Call "%~dp0installx86.bat"

goto fin

:fin