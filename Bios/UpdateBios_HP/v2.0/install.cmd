xcopy "%~dp0module" "c:\Program Files\WindowsPowerShell\Modules\" /S /Y /E
powershell -executionpolicy bypass -file "%~dp0updatebiosHP.ps1"

:: NEED Reboot manually or schedule