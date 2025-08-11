if exist c:\windows\syswow64 "%~dp0setup64.exe" /S /v "/qn REBOOT=R"
if NOT exist c:\windows\syswow64 "%~dp0setup.exe" /S /v "/qn REBOOT=R"
