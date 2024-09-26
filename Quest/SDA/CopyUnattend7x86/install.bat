if exist c:\windows goto partC
if exist d:\windows goto partD

:partC
md d:\windows\panther
copy "%~dp0unattend7x86.xml" c:\windows\panther\unattend.xml /Y
goto Fin

:PartD
md d:\windows\panther
copy "%~dp0unattend7x86.xml" d:\windows\panther\unattend.xml /Y
goto Fin

:Fin



