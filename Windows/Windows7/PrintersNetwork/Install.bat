REM nom du fichier INF
Set FichierINFx64=CNLB0FA64.INF
Set FichierINFx86=CNLB0F.INF

REM nom du drivers à utiliser==>faire un copier coller du nom depuis le fichier inf
Set NomDrivers=Canon iR1133 UFRII LT

REM adresse IP de l'imprimante
Set AdresseIP=192.168.0.112

Rem Nom de l'imprimante qui devra etre affiche
Set NomImprimante=COPIEUR BE



if EXIST c:\Windows\syswow64 goto archix64

:Archix86
cscript %windir%\system32\Printing_Admin_Scripts\fr-fr\prnport.vbs -a -r IP_%AdresseIP% -h %AdresseIP% -o raw -n 9100
rundll32 %windir%\system32\printui.dll,PrintUIEntry /if /f "%~dp0x86\%FichierINFx86%" /r "IP_%AdresseIP%" /m "%NomDrivers%" /z /b "%NomImprimante%"
goto fin

:archix64
cscript %windir%\system32\Printing_Admin_Scripts\fr-fr\prnport.vbs -a -r IP_%AdresseIP% -h %AdresseIP% -o raw -n 9100
rundll32 %windir%\system32\printui.dll,PrintUIEntry /if /f "%~dp0x64\%FichierINFx64%" /r "IP_%AdresseIP%" /m "%NomDrivers%" /z /b "%NomImprimante%"
Goto fin

:fin
timeout 10

