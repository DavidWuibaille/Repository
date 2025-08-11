:Install
c:\windows\system32\cscript.exe //b //e:vbscript "%~dp0ChangePathXML.vbs"
"%~dp0setup.exe" /configure "%~dp0configuration.xml"
