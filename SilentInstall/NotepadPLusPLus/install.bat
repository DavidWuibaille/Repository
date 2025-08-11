"%~dp0npp.7.5.6.Installer.exe" /S

md C:\Users\%username%\AppData\Roaming\Notepad++
md C:\Users\default\AppData\Roaming\Notepad++

copy "%~dp0config.xml" C:\Users\%username%\AppData\Roaming\NOTEPA~1 /Y
copy "%~dp0config.xml" C:\Users\default\AppData\Roaming\NOTEPA~1 /Y

