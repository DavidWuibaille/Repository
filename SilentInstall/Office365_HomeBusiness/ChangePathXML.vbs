' Le VBS permet de remplacer le chemin des sources d'office dans le fichier configuration.xml
' Le fichier est mis dans un tableau, le tableau est ensuite reinjecté dans le XML

Set Fso = CreateObject( "Scripting.FileSystemObject" )
Set shell = CreateObject("WScript.Shell")

Dim Tab
Redim tab(0)
on error resume next

' Ajout du fichier XML dans un tableau
If Fso.FileExists(GetPath & "configuration.xml") Then
	set inf= Fso.OpenTextFile(GetPath & "configuration.xml")
	While inf.AtEndOfStream <> True
		Ligne = inf.readline
		
		' Chaque ligne du tableau correspond a une ligne du fichier XML
		Tab(Ubound(tab)) = Ligne
		Redim preserve Tab(Ubound(tab)+1)
	Wend
End If
inf.close

' Ecrasement du fichier XML pour le remplacer par les lignes du tableau
Set infW = Fso.CreateTextFile(GetPath & "configuration.xml",True)
For i=0 To (Ubound(Tab) -1)
	' Remplacement de la ligne contenant le chemin des sources Office pour le chemin courant
	If Instr(Tab(i),"<Add SourcePath=") <> 0 Then
		Tab(i) = "  <Add SourcePath=" & chr(34) & Left(Getpath,Len(Getpath)-1) & chr(34) & " OfficeClientEdition="& chr(34) & "32" & chr(34) & " >"
	End If
	
	CodeRetour = infw.writeLine(Tab(i))
Next
infW.close
 
Function GetPath()
 Dim path
 Deftpath = WScript.ScriptFullName
 GetPath = Left(Deftpath, InStrRev(Deftpath, "\"))
End Function