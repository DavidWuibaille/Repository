rd c:\sysprep /Q /S
md c:\sysprep
xcopy "%~dp0sysprep\*.*" c:\sysprep\ /S /Y /E
cscript c:\sysprep\massstorage.vbs