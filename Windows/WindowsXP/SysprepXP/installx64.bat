rd c:\sysprep /Q /S
md c:\sysprep
xcopy "%~dp0sysprep_x64\*.*" c:\sysprep\ /S /Y /E
cscript c:\sysprep\massstorage.vbs