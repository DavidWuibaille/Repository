' add custom
Const HKEY_LOCAL_MACHINE = &H80000002
CopyLocal = "c:\dsi"

Set Fso = CreateObject("Scripting.FileSystemObject")
Set objshell = CreateObject("Wscript.Shell")

If Fso.FileExists(CopyLocal & "\Drivers\DriversPostInstall\install.bat") = True Then
	Coderetour = objshell.run(CopyLocal & "\Drivers\DriversPostInstall\install.bat",,True)
End If
Wscript.quit 0



Function TraceLog(FichierLog,Commentaire)
	On error resume Next
	Dim oFso, fich
	Set oFso = CreateObject("Scripting.FileSystemObject")
	Set fich = oFso.OpenTextFile(FichierLog,8,True)
	fich.writeline cstr(Date) & " " & cstr(Time) & " | " & Commentaire
 	fich.close
	On error goto 0
End Function 
