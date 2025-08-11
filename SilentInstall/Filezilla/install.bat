"%~dp0FileZilla_3.33.0_win32-setup.exe" /S

if EXIST "C:\Program Files (x86)\FileZilla FTP Client\docs" copy "%~dp0fzdefaults.xml" "C:\Program Files (x86)\FileZilla FTP Client\docs" /Y
if EXIST "C:\Program Files\FileZilla FTP Client\docs" copy "%~dp0fzdefaults.xml" "C:\Program Files\FileZilla FTP Client\docs" /Y
