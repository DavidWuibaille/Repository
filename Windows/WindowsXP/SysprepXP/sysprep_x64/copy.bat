rd c:\sysprep /Q /S
md c:\sysprep
xcopy "%~dp0*.*" c:\sysprep\ /S /Y /E
cscript c:\sysprep\massstorage.vbs