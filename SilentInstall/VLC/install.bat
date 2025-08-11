"%~dp0vlc-3.0.3-win32.exe" /S
xcopy "%~dp0vlc\*.*" "C:\Users\%username%\AppData\Roaming\vlc\" /F /E /Y
xcopy "%~dp0vlc\*.*" "C:\Users\Default\AppData\Roaming\vlc\" /F /E /Y
del "C:\Users\Public\Desktop\VLC media player.lnk"

md "C:\Users\%username%\AppData\Roaming\vlc\"
md "C:\Users\Default\AppData\Roaming\vlc"
copy "%~dp0vlcrc.txt" "C:\Users\%username%\AppData\Roaming\vlc\vlcrc" /Y
copy "%~dp0vlcrc.txt" "C:\Users\Default\AppData\Roaming\vlc\vlcrc" /Y



