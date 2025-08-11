if EXIST C:\Windows\SysWOW64 Goto x64
Goto x86
:x64
"%~dp0UltraVNC_1_2_12_X64_Setup.exe" /loadinf="%~dp0installation.inf" /Verysilent /norestart
Goto Param

:x86
"%~dp0UltraVNC_1_2_12_X86_Setup.exe" /loadinf="%~dp0installation.inf" /Verysilent /norestart
Goto Param

:Param
timeout 3
net stop uvnc_service
timeout 3
xcopy "%~dp0config\*.*" "C:\Program Files\uvnc bvba\UltraVnc\" /S /Y /E
net start uvnc_service
netsh advfirewall firewall add rule name="VNC(5900)" dir=in action=allow protocol=tcp localport=5900

:FIN