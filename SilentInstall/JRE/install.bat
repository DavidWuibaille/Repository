
msiexec /i "%~dp0jre1.8.0_17164.msi" /qn AUTOUPDATECHECK=0 IEXPLORER=1 JAVAUPDATE=0 JU=0 MOZILLA=1

regedit /s "%~dp0Update_x64.reg"
regedit /s "%~dp0Update_x86.reg"

%SystemRoot%\Sysnative\regedit.exe "%~dp0Update_x64.reg"
%SystemRoot%\Sysnative\regedit.exe "%~dp0Update_x86.reg"

exit /B 0






