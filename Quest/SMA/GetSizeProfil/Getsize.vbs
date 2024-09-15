Set Fso = CreateObject( "Scripting.FileSystemObject" )
Set shell = CreateObject("WScript.Shell")

Set InfW = Fso.CreateTextFile("c:\Windows\temp\TailleProfils.log", True)
CodeRetour = InfW.writeLine("### Taille Profil ###")

strComputer = "."
On Error Resume Next
If Fso.FolderExists("c:\Documents and settings") Then
	Set objFolder = Fso.GetFolder("c:\Documents and settings")
	If err.number <> 0 then CodeRetour = InfW.writeLine("Error Get c:\Documents and settings : " & err.description)
	Set objSubFolders = objFolder.SubFolders
	
	For Each objSubFolder in objSubFolders
		Set queriesFolder = Fso.GetFolder("c:\Documents and settings\" & objSubFolder.name)
		If err.number <> 0 then CodeRetour = InfW.writeLine("Error Get c:\Documents and settings\" & objSubFolder.name & " : " & err.description)
		
		CodeRetour = InfW.writeLine("c:\Documents and settings\" & objSubFolder.name & " = " & Round(queriesFolder.Size/1024/1024) & " Mo")
	Next
End If

If Fso.FolderExists("c:\Users") Then
	On Error Resume Next
	Set objFolder = Fso.GetFolder("c:\Users")
	If err.number <> 0 then CodeRetour = InfW.writeLine("Error Get c:\Users : " & err.description)
	Set objSubFolders = objFolder.SubFolders
	For Each objSubFolder in objSubFolders
	
		CodeRetour = Shell.run("cmd /c " & chr(34) & Getpath & "du.exe" & chr(34) & " /acceptEula -q -c " & "c:\Users\" & objSubFolder.name & ">c:\windows\temp\du.txt",0,True)
		Set Fso = CreateObject("Scripting.FileSystemObject")
		If Fso.FileExists("c:\windows\temp\du.txt") Then
		
			set inf= Fso.OpenTextFile("c:\windows\temp\du.txt")
			While inf.AtEndOfStream <> True 
				Ligne = Inf.Readline
				If Instr(Ligne,"Path") = 0 Then
					Temp = Split(Ligne,",")
					CodeRetour = InfW.writeLine(Temp(0) & " : " & Cint(Temp(Ubound(Temp)) / 1024) & " Mo") 
				End If
			Wend
			inf.close
		End If
		
		

		CodeRetour = InfW.writeLine("c:\Users\" & objSubFolder.name & " = " & Round(queriesFolder.Size/1024/1024) & " Mo")
	Next


End If

infW.close


Function GetPath()
 Dim path
 path = WScript.ScriptFullName
 GetPath = Left(path, InStrRev(path, "\"))
End Function

