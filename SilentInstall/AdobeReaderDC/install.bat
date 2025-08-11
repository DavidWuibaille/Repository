Set cmdpowershell=powershell
Set cmdreg=reg
if defined PROCESSOR_ARCHITEW6432 Set cmdpowershell=%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe
if defined PROCESSOR_ARCHITEW6432 Set cmdreg=%SystemRoot%\sysnative\reg.exe


msiexec /i "%~dp0AcroRead.msi" TRANSFORMS="%~dp0AcroRead.mst" /qn /lie "C:\windows\temp\INSTALL_AdobeReaderDC_20200615_BASE.log" REBOOT=ReallySuppress
msiexec /p "%~dp0AcroRdrDCUpd2001320064_MUI.msp" /qn /lie "C:\windows\temp\INSTALL_AcroRdrDCUpd2001320064_MSP.log" REBOOT=ReallySuppress
Exit /B 0

