if not exist c:\Drivers md c:\Drivers


Set cmdreg=reg
if defined PROCESSOR_ARCHITEW6432 Set cmdreg=%SystemRoot%\sysnative\reg.exe

:: Setup
echo ************************************************************************** >>c:\windows\temp\Upgrade1803.log
echo Start>>c:\windows\temp\Upgrade1803.log
"%~dp0setup.exe" /auto Upgrade /installdrivers c:\Drivers /pkey W269N-WFGWX-YVC9B-4J6C9-T83GX /DynamicUpdate Disable /compat IgnoreWarning /postoobe "%~dp0setupcomplete.cmd" /CopyLogs c:\windows\temp\UpgradeW10
echo End>>c:\windows\temp\Upgrade1803.log

