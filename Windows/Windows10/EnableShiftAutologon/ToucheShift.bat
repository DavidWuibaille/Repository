if defined PROCESSOR_ARCHITEW6432 goto sysnative

:native
powershell -noprofile -command "Set-ExecutionPolicy bypass LocalMachine"
reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\UserSwitch /v Enabled /t REG_DWORD /d 1 /f
powershell -file "%~dp0Heritage.ps1"
powershell -file "%~dp0DroitsTeur.ps1"
powershell -file "%~dp0DroitsTor.ps1"
powershell -file "%~dp0deny.ps1"
Goto Fin

:sysnative
%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe -noprofile -command "Set-ExecutionPolicy bypass LocalMachine"
%SystemRoot%\Sysnative\cmd.exe /c reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\UserSwitch /v Enabled /t REG_DWORD /d 1 /f
%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe -file "%~dp0Heritage.ps1"
%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe -file "%~dp0DroitsTeur.ps1"
%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe -file "%~dp0DroitsTor.ps1"
%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe -file "%~dp0deny.ps1"
Goto Fin

:Fin

