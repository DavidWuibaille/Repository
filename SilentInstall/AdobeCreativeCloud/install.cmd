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

md c:\exploit
md c:\exploit\package

::Call "%~dp0uninstall.cmd"

rd /S /Q c:\exploit\package\CC_Light_2018_V2
rd /S /Q c:\exploit\package\CC_Light_2019
rd /S /Q c:\exploit\package\CC_Light_2020
rd /S /Q c:\exploit\package\CC_Light_2021

"%~dp07z.exe" x "%~dp0CC_Light_2021_fr_FR_WIN_64.zip" -oc:\exploit\package
timeout 30
"c:\exploit\package\CC_Light_2021\Build\setup.exe" --silent
timeout 30
rd /S /Q c:\exploit\package\CC_Light_2021
timeout 30