:: Version 2.0 : 20180328
::@echo off

::  Get Computer model Name=>HP Version=>Lenovo
SET Modele="NOAFFECT"
SET ModeleL="NOAFFECT"
FOR /F "tokens=2 delims==" %%A IN ('WMIC csproduct GET Name /VALUE ^| FIND /I "Name="') DO SET Modele=%%A
FOR /F "tokens=2 delims==" %%A IN ('WMIC csproduct GET Version /VALUE ^| FIND /I "Version="') DO SET ModeleL=%%A

::  Get Computer Vendor
FOR /F "tokens=2 delims==" %%A IN ('wmic csproduct get vendor /VALUE ^| FIND /I "Vendor="') DO SET Marque=%%A

::  Get OS Archi
SET Archi=X86
IF EXIST C:\Windows\SysWOW64\cmd.exe SET Archi=X64

::  Get OS Version
reg.exe load HKLM\0000 "C:\WINDOWS\system32\config\software"
for /f "tokens=3*" %%A in ('reg query "HKLM\0000\Microsoft\Windows NT\CurrentVersion" /v "ProductName"') do SET "WINV=%%A %%B"
Reg.exe unload HKLM\0000


:: *************** Create Folder drivers ************************************
if EXIST c:\PnPdrivers rd c:\PnPdrivers /S /Q
md c:\PnPdrivers

ECHO Computer model:%Modele% >>c:\Drivers\Install.log
ECHO Computer modelL:%ModeleL% >>c:\Drivers\Install.log
ECHO Computer Make :%Marque% >>c:\Drivers\Install.log
ECHO Computer Archi:%Archi% >>c:\Drivers\Install.log
ECHO Computer Win  :%WINV% >>c:\Drivers\Install.log
ECHO ------------------------------------------- >>c:\Drivers\Install.log
ipconfig /all >>c:\Drivers\Install.log
ECHO ------------------------------------------- >>c:\Drivers\Install.log


::  #################### Nettoyage variable MAKE ####################
IF /I "%Marque%" == "Dell Inc." SET Marque=Dell
IF /I "%Marque%" == "Hewlett-Packard" SET Marque=HP
IF /I "%Marque%" == "Phoenix Technologies LTD" SET Marque=VM
IF /I "%Marque%" == "VMware, Inc." SET Marque=VM
IF /I "%Marque%" == "TOSHIBA" SET Marque=TOSHIBA
IF /I "%Marque%" == "Microsoft Corporation" SET Marque=Microsoft
IF /I "%Marque%" == "Wacom Co.,Ltd" SET Marque=Wacom
IF /I "%Marque%" == "Aava Mobile Oy" SET Marque=Aava
IF /I "%Marque%" == "WINCOR NIXDORF" SET Marque=WINCOR
IF /I "%Marque%" == "LENOVO" SET Marque=LENOVO

::  ####################Nettoyage variable MODEL ####################
::  ******************** HP *****************************************
IF /I "%Modele%" == "HP EliteBook Folio 9470m" SET Modele=9470m
IF /I "%Modele%" == "HP EliteBook 840 G1" SET Modele=840G1
IF /I "%Modele%" == "HP EliteBook 840 G2" SET Modele=840G2
IF /I "%Modele%" == "HP EliteBook 850 G3" SET Modele=850G3
IF /I "%Modele%" == "HP EliteBook 840 G3" SET Modele=840G3
IF /I "%Modele%" == "HP EliteBook 840 G5" SET Modele=840G5
IF /I "%Modele%" == "HP EliteBook 850 G5" SET Modele=850G5
IF /I "%Modele%" == "HP EliteBook 840 G6" SET Modele=840G6
IF /I "%Modele%" == "HP EliteBook 850 G6" SET Modele=850G6
IF /I "%Modele%" == "HP rp5800" SET Modele=rp5800
IF /I "%Modele%" == "HP RP5800 RETAIL SYSTEM" SET Modele=rp5800
IF /I "%Modele%" == "HP rp5800 retail system" SET Modele=rp5800
IF /I "%Modele%" == "HP rp 5800 Retail System" SET Modele=rp5800
IF /I "%Modele%" == "HP rp5800 Retail System" SET Modele=rp5800
IF /I "%Modele%" == "HP rp5800 Base Model Retail System" SET Modele=rp5800
IF /I "%Modele%" == "HP RP5 Retail System Model 5810" SET Modele=rp5810
IF /I "%Modele%" == "HP RPS RETAIL SYSTEM, MODEL 5810" SET Modele=rp5810
IF /I "%Modele%" == "HP RP5 Retail Model 5810" SET Modele=rp5810
IF /I "%Modele%" == "HP RP5 5810" SET Modele=rp5810
IF /I "%Modele%" == "HP rp5700 Business System" SET Modele=rp5700BS
IF /I "%Modele%" == "DSDT_PRJ" SET Modele=rp5700BS
IF /I "%Modele%" == "HP Compaq rp5700" SET Modele=rp5700BS
IF /I "%Modele%" == "HP rp5700" SET Modele=rp5700BS
IF /I "%Modele%" == "HP rp5700 Business Desktop" SET Modele=rp5700BS
IF /I "%Modele%" == "HP Compaq dc7700 Small Form Factor" SET Modele=dc7700SFF
IF /I "%Modele%" == "HP Compaq dc7800 Small Form Factor" SET Modele=dc7800SFF
IF /I "%Modele%" == "HP ProBook 6570b" SET Modele=6570b
IF /I "%Modele%" == "HP ProBook 650 G1" SET Modele=650G1
IF /I "%Modele%" == "HP Z620 Workstation" SET Modele=Z620
IF /I "%Modele%" == "HP Z420 Workstation" SET Modele=Z420
IF /I "%Modele%" == "HP Z400 Workstation" SET Modele=Z400
IF /I "%Modele%" == "HP Z440 Workstation" SET Modele=Z440
IF /I "%Modele%" == "HP ProBook 6560b" SET Modele=6560b
IF /I "%Modele%" == "HP ProBook 6560b (WX753AV)" SET Modele=6560b
IF /I "%Modele%" == "HP ProBook 6360b" SET Modele=6360b
IF /I "%Modele%" == "HP EliteOne 800 G1 Touch AiO" SET Modele=800G1AiO
IF /I "%Modele%" == "HP EliteOne 800 G2 23-in Touch AiO" SET Modele=800G2AiO
IF /I "%Modele%" == "HP EliteOne 800 G2 23-in Non-Touch AiO" SET Modele=800G2AiO
IF /I "%Modele%" == "HP EliteDesk 800 G2 SFF" SET Modele=800G2SFF
IF /I "%Modele%" == "HP EliteDesk 800 G3 SFF" SET Modele=800G3SFF
IF /I "%Modele%" == "HP EliteDesk 800 G4 SFF" SET Modele=800G4SFF
IF /I "%Modele%" == "HP EliteDesk 800 G5 SFF" SET Modele=800G5SFF
IF /I "%Modele%" == "HP ZBook Studio G3" SET Modele=ZBookG3
IF /I "%Modele%" == "HP ZBook Studio G4" SET Modele=ZBookG4
IF /I "%Modele%" == "HP ZBook Studio G5" SET Modele=ZBookG5
IF /I "%Modele%" == "HP ZBook Studio x360 G5" SET Modele=ZBookG5
IF /I "%Modele%" == "HP EliteOne 800 G3 23.8-in Non-Touch AiO" SET Modele=800G3AiO
IF /I "%Modele%" == "HP EliteOne 800 G3 23.8-in Touch AiO" SET Modele=800G3AiO
IF /I "%Modele%" == "HP EliteOne 800 G4 23.8-in Non-Touch AiO" SET Modele=800G4AiO
IF /I "%Modele%" == "HP EliteOne 800 G4 23.8-in Touch AiO" SET Modele=800G4AiO
IF /I "%Modele%" == "HP RP5810 POS" SET Modele=rp5810
IF /I "%Modele%" == "HP RP5810 POS " SET Modele=rp5810
IF /I "%Modele%" == "RP581P" SET Modele=rp5810
IF /I "%Modele%" == "HP MP9 G4 Retail System" SET Modele=MP9G4
IF /I "%Modele%" == "HP ProDesk 600 G1 TWR" SET Modele=600G1
IF /I "%Modele%" == "HP Engage Flex Pro-C" SET Modele=FlexProRetail
IF /I "%Modele%" == "HP Engage Flex Pro" SET Modele=FlexProRetail


::  ******************** Dell *****************************************
IF /I "%Modele%" == "Inspiron 3477 AIO" SET Modele=Inspiron3477AIO
IF /I "%Modele%" == "Latitude 7480" SET Modele=Latitude7480
IF /I "%Modele%" == "Latitude 7390" SET Modele=Latitude7390
IF /I "%Modele%" == "Latitude 7380" SET Modele=Latitude7380
IF /I "%Modele%" == "Latitude 5285" SET Modele=Latitude5285
IF /I "%Modele%" == "Latitude 7300" SET Modele=7300
IF /I "%Modele%" == "Latitude 7400" SET Modele=7400
IF /I "%Modele%" == "Latitude 7400 2-in-1" SET Modele=7400_2IN1
IF /I "%Modele%" == "XPS Notebook 7390 2-in-1" SET Modele=7390_2IN1
IF /I "%Modele%" == "XPS13 7390 2-in-1" SET Modele=7390_2IN1
IF /I "%Modele%" == "XPS 13 7390 2-in-1" SET Modele=7390_2IN1
IF /I "%Modele%" == "XPS Notebook 7390" SET Modele=7390
IF /I "%Modele%" == "Precision 5520" SET Modele=5520
IF /I "%Modele%" == "Venue 11 Pro 7130" SET Modele=Venue7130
IF /I "%Modele%" == "Venue 11 Pro 7130 vPro" SET Modele=Venue7130
IF /I "%Modele%" == "OptiPlex 5050" SET Modele=5050
IF /I "%Modele%" == "OptiPlex 5060" SET Modele=5060
IF /I "%Modele%" == "Precision Tower 3430" SET Modele=Precision3430
IF /I "%Modele%" == "XPS 13 9365" SET Modele=XPS139365


::  ******************** Specifique *****************************************
IF /I "%Modele%" == "VMware Virtual Platform" SET Modele=VMWare
IF /I "%Modele%" == "VMware7,1" SET Modele=VMWare
IF /I "%Modele%" == "Virtual Machine" SET Modele=HyperV
IF /I "%Modele%" == "BEETLE /MIII" SET Modele=BEETLEMIII
IF /I "%Modele%" == "INARI8-LTDN-1" SET Modele=INARI8

::  ******************** WACOM *****************************************
IF /I "%Modele%" == "Wacom MobileStudio Pro 16" SET Modele=MobileStudioPro16

::  ******************** Thoshiba *****************************************
IF /I "%Modele%" == "PORTEGE Z30-A" SET Modele=Z30

::  ******************** Microsoft *****************************************
IF /I "%Modele%" == "Surface Pro 3" SET Modele=SPro3
IF /I "%Modele%" == "Surface Pro 4" SET Modele=SPro4
IF /I "%Modele%" == "Surface Pro" SET Modele=SPro

::  ******************** LENOVO *****************************************
IF /I "%ModeleL%" == "ThinkCentre E73" SET Modele=E73
IF /I "%ModeleL%" == "ThinkCentre M83" SET Modele=M83
IF /I "%ModeleL%" == "ThinkCentre M93z" SET Modele=M93
IF /I "%ModeleL%" == "ThinkPad X1 Carbon 4th" SET Modele=X1Carbon4th
IF /I "%ModeleL%" == "ThinkPad X260" SET Modele=x260
IF /I "%ModeleL%" == "ThinkPad E460" SET Modele=E460
IF /I "%ModeleL%" == "ThinkPad E550" SET Modele=E550
IF /I "%ModeleL%" == "ThinkPad E450" SET Modele=E450
IF /I "%ModeleL%" == "ThinkPad S2" SET Modele=S2
IF /I "%ModeleL%" == "ThinkPad X250" SET Modele=x250
IF /I "%ModeleL%" == "ThinkPad X230" SET Modele=x230
IF /I "%ModeleL%" == "ThinkPad X200" SET Modele=x200
IF /I "%ModeleL%" == "ThinkPad X240" SET Modele=x240
IF /I "%ModeleL%" == "Lenovo B40-70" SET Modele=B4070


::  ####################Nettoyage variable OS ####################
IF /I "%WINV%" == "Windows 8.1 Pro" SET WINV=Win81
IF /I "%WINV%" == "Windows 7 Professional" SET WINV=Win7
IF /I "%WINV%" == "Windows Embedded Standard" SET WINV=WinPOS7
IF /I "%WINV%" == "Windows Embedded 8.1 Industry Pro" SET WINV=Win81
IF /I "%WINV%" == "Windows 10 Enterprise" SET WINV=Win10
IF /I "%WINV%" == "Windows 10 Pro" SET WINV=Win10
IF /I "%WINV%" == "Windows 10 Enterprise 2016 LTSB" SET WINV=Win10LTSB
IF /I "%WINV%" == "Windows 10 Enterprise LTSC 2019" SET WINV=Win10LTSB
IF /I "%WINV%" == "Windows Server 2016 Standard" SET WINV=Win2016



::  ************************************************************************
ECHO Computer model:%Modele% >>c:\Drivers\Install.log
ECHO Computer Make :%Marque% >>c:\Drivers\Install.log
ECHO Computer Archi:%Archi% >>c:\Drivers\Install.log
ECHO Computer Win  :%WINV% >>c:\Drivers\Install.log
Net use >>c:\Drivers\Install.log
ECHO ---------------------------------------------- >>c:\Drivers\Install.log

:SecondPass
:: *************** Native Drivers ***************
echo check : y:\SCX\ToolsW7\PnPDrivers\%Marque%_%Modele%\%WINV%\%Archi% >>c:\Drivers\Install.log
IF EXIST y:\SCX\ToolsW7\PnPDrivers\%Marque%_%Modele%\%WINV%\%Archi% (
xcopy y:\SCX\ToolsW7\PnPDrivers\%Marque%_%Modele%\%WINV%\%Archi%\*.* c:\Drivers\ /S /Y /E >>c:\Drivers\Install.log
Goto ChoiceInjectDrivers
)

echo check : y:\Store\ToolsW7\PnPDrivers\%Marque%_%Modele%\%WINV%\%Archi% >>c:\Drivers\Install.log
IF EXIST y:\Store\ToolsW7\PnPDrivers\%Marque%_%Modele%\%WINV%\%Archi% (
xcopy y:\Store\ToolsW7\PnPDrivers\%Marque%_%Modele%\%WINV%\%Archi%\*.* c:\Drivers\ /S /Y /E >>c:\Drivers\Install.log
Goto ChoiceInjectDrivers
)

echo check : y:\Log\ToolsW7\PnPDrivers\%Marque%_%Modele%\%WINV%\%Archi% >>c:\Drivers\Install.log
IF EXIST y:\Log\ToolsW7\PnPDrivers\%Marque%_%Modele%\%WINV%\%Archi% (
xcopy y:\Log\ToolsW7\PnPDrivers\%Marque%_%Modele%\%WINV%\%Archi%\*.* c:\Drivers\ /S /Y /E >>c:\Drivers\Install.log
Goto ChoiceInjectDrivers
)

echo check : y:\KISS\ToolsW7\PnPDrivers\%Marque%_%Modele%\%WINV%\%Archi% >>c:\Drivers\Install.log
IF EXIST y:\KISS\ToolsW7\PnPDrivers\%Marque%_%Modele%\%WINV%\%Archi% (
xcopy y:\KISS\ToolsW7\PnPDrivers\%Marque%_%Modele%\%WINV%\%Archi%\*.* c:\Drivers\ /S /Y /E >>c:\Drivers\Install.log
Goto ChoiceInjectDrivers
)

IF /I "%WINV%" == "Win10LTSB" (
SET WINV=Win10
Goto SecondPass
)

:ChoiceInjectDrivers
IF /I "%WINV%" == "WinPOS7" goto INJECTREGEDIT
goto INJECTDISM

:INJECTREGEDIT
echo ************ Inject Regedit ************
reg.exe load HKLM\0000 "C:\WINDOWS\system32\config\software" 
reg add "HKLM\0000\Microsoft\Windows\CurrentVersion" /v DevicePath /t REG_EXPAND_SZ /d "c:\windows\inf;c:\PnPdrivers" /f  1>>c:\Drivers\Install.log 
Reg.exe unload HKLM\0000

:INJECTDISM
echo ************ Inject DISM ***************
rem Exclude ADD folder to dism
for /f %%i In ('dir /b /ad "C:\PnPdrivers"') Do If Not "%%i"=="ADD" dism /image:c:\ /Add-driver /driver:c:\Drivers\%%i /Recurse /ForceUnsigned >>c:\Drivers\Install.log

