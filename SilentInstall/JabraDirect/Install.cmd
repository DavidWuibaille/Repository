@echo off

REM Initialisation des variables vardate et vartime
set vardate=%DATE:/=% 
set vartime=%time:~0,2%%time:~3,2%

REM Verification de la présence du repertoire C:\exploit et C:\exploit\log
If not exist "C:\exploit" md "C:\exploit"
If not exist "C:\exploit\log" md "C:\exploit\log"

REM Installation de l'application
"%~dp0JabraDirectSetup.exe" /install /quiet /norestart /log "C:\exploit\log\INSTALL_Jabra_5.11.01302_%vardate%_%vartime%.log"

REM Copie du raccourci sur le bureau
xcopy /e /i /y "c:\Programdata\microsoft\windows\Start Menu\Programs\Jabra\Jabra Direct.lnk" "C:\Users\public\Desktop"

goto fin

:fin