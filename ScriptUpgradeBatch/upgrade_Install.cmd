Set LogFile=c:\exploit\log\migrationw11.log
Set LDMSserver=ldcore.kiabi.fr
md c:\exploit
md c:\exploit\log
md c:\pnpdrivers
set SourceISO=%~dp0

Set cmdreg=reg
Set cmdpowershell=powershell
Set cmddism=dism
if defined PROCESSOR_ARCHITEW6432 Set cmdreg=%SystemRoot%\sysnative\reg.exe
if defined PROCESSOR_ARCHITEW6432 Set cmdpowershell=%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe
if defined PROCESSOR_ARCHITEW6432 Set cmddism=%SystemRoot%\Sysnative\cmd.exe /c Dism

:Preparation
call "%~dp0upgrade_GetPendingReboot.cmd"
if %ERRORLEVEL% NEQ 0 Exit /B %ERRORLEVEL%
%cmdpowershell% -noprofile -command "set-executionPolicy Bypass localmachine"
call "%~dp0upgrade_Cleanup.cmd"

echo ---------------- UPGRADE %date% %time%--------------------------------->>%LogFile%
:: ################# Set WimFile and Index ###################

:InitCulture
echo InitCulture>>%LogFile%
:: Get culture du poste
%cmdpowershell% -command [CultureInfo]::InstalledUICulture.Name>c:\windows\temp\InstalledUICulture.txt
set /p culture= < c:\windows\temp\InstalledUICulture.txt
findstr /m "CultureInfo" c:\windows\temp\InstalledUICulture.txt
IF %ERRORLEVEL% EQU 0 set culture=%Language%

Set IndexWIM=0
IF /I %culture% EQU en-US Set IndexWIM=1
IF /I %culture% EQU es-ES Set IndexWIM=2
IF /I %culture% EQU fr-FR Set IndexWIM=3
IF /I %culture% EQU it-IT Set IndexWIM=4
IF /I %culture% EQU pt-PT Set IndexWIM=5
echo IndexWIM=%IndexWIM%
echo IndexWIM=%IndexWIM% >>%LogFile%


:StartSetup
echo StartSetup>>%LogFile%
@echo off
"%LDMS_LOCAL_DIR%\..\SendTaskStatus.exe" -core=%LDMSserver% -taskid=%task_ID% -retcode=%errorlevel% -message=Setupexe
echo setupexe      ="%SourceISO%setup.exe"
"%SourceISO%setup.exe" /quiet /EULA accept /noreboot /auto Upgrade /installfrom "%SourceISO%sources\install.wim" /imageindex %IndexWIM% /installdrivers c:\pnpdrivers /DynamicUpdate Disable /postoobe "%SourceISO%upgrade_setupcomplete.cmd"
Set RetourCode=%errorlevel%


:Fin
echo Fin>>%LogFile%
@echo off
Echo RetourCode=%RetourCode%
Echo RetourCode=%RetourCode% >>%LogFile%
"%LDMS_LOCAL_DIR%\..\SendTaskStatus.exe" -core=%LDMSserver% -taskid=%task_ID% -retcode=%RetourCode% -message=%RetourCode%
if %RetourCode% NEQ 0 rd c:\MigrationW11 /S /Q
::Exit /B %RetourCode%
