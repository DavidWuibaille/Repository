'Nom des repertoire exportant les drivers
Set Fso = CreateObject("Scripting.FileSystemObject")
Set Shell = CreateObject("Wscript.Shell")

Dim S_DP, S_Export
Dim ExportTab

On error resume next

Set Fso = CreateObject("Scripting.FileSystemObject")
If Fso.FileExists(GetPath & "ExportMDT.ini") Then
	set inf= Fso.OpenTextFile(GetPath & "ExportMDT.ini")
	While inf.AtEndOfStream <> True
		Ligne = Inf.Readline
		If instr(Ligne,"=") <> 0 Then
			Temp = Split(Ligne,"=")
			If Instr(UCase(Ligne),"TEXT_NOMDP") 		<> 0 Then S_DP = Trim(Temp(1))
			If Instr(UCase(Ligne),"TEXT_NOMREPEXPORT") 	<> 0 Then S_Export = Trim(Temp(1))
		End If
	Wend
	inf.close
End If

if S_DP = "" Or S_Export = "" Then msgbox "Error INI"
'If Fso.FolderExists(S_Export) = True Then CodeRetour = Fso.DeleteFolder(S_Export,True)
If Fso.FolderExists(S_Export) = False Then CodeRetour = Fso.CreateFolder(S_Export)


' #################### export Drivers ####################################
wscript.echo "##### Drivers #####"
redim ExportTab(0)
Set xmlDoc = CreateObject("Microsoft.XMLDOM")
xmlDoc.Async = "false"
xmlDoc.Load(S_DP & "\control\DriverGroups.xml")
For Each personneElement In xmlDoc.selectNodes("/groups/group")
	Name =  personneElement.selectSingleNode("Name").text
	If Name <> "hidden" and Name <> "default" Then
		If Fso.FolderExists(S_Export & "\" & "Drivers") = False 		Then CodeRetour = Fso.CreateFolder(S_Export & "\" & "Drivers")
		If Fso.FolderExists(S_Export & "\" & "Drivers\" & Name) = False Then CodeRetour = Fso.CreateFolder(S_Export & "\" & "Drivers\" & Name)
		Set Member = personneElement.selectNodes("Member")
		If Member.length > 0 Then
			For Each MemberElement In Member
				ExportTab(UBound(ExportTab)) = S_Export & "\" & "Drivers\" & Name & ";" & MemberElement.text
				Redim Preserve ExportTab(UBound(ExportTab)+1)
			Next
		End If
	End If
Next
Set xmlDoc = Nothing
Set xmlDoc = CreateObject("Microsoft.XMLDOM")
xmlDoc.Async = "false"
xmlDoc.Load(S_DP & "\control\Drivers.xml")
For Each guidElement In xmlDoc.selectNodes("/drivers/driver")
	guid =  guidElement.getAttribute("guid")
	For i = 0 To (Ubound(ExportTab) -1)
		temp = Split(ExportTab(i),";")
		If Temp(1) = guid Then
			Source = guidElement.selectSingleNode("Source").text
			Source = S_DP & "\" & right(Source,Len(Source)-2)
			Source = Left(Source, InStrRev(Source, "\")-1)

			wscript.echo Source
			Temp2 = Split(Source,"\")
			wscript.Echo Temp(0) & "\" & Temp2(Ubound(Temp2))
			If Fso.FolderExists(Source) = True Then
				If Fso.FolderExists(Temp(0) & "\" & Temp2(Ubound(Temp2))) = False Then
					CodeRetour = Fso.CopyFolder(Source,Temp(0) & "\" & Temp2(Ubound(Temp2)),True)
				End If
			End If
		End If
	Next
Next


' #################### export Packages ####################################
wscript.echo "##### packages #####"
redim ExportTab(0)
Set xmlDoc = Nothing
Set xmlDoc = CreateObject("Microsoft.XMLDOM")
xmlDoc.Async = "false"
xmlDoc.Load(S_DP & "\control\PackageGroups.xml")
For Each personneElement In xmlDoc.selectNodes("/groups/group")
	Name =  personneElement.selectSingleNode("Name").text
	If Name <> "hidden" and Name <> "default" Then
		If Fso.FolderExists(S_Export & "\" & "Packages") = False 		Then CodeRetour = Fso.CreateFolder(S_Export & "\" & "Packages")
		If Fso.FolderExists(S_Export & "\" & "Packages\" & Name) = False Then CodeRetour = Fso.CreateFolder(S_Export & "\" & "Packages\" & Name)
		Set Member = personneElement.selectNodes("Member")
		If Member.length > 0 Then
			For Each MemberElement In Member
				ExportTab(UBound(ExportTab)) = S_Export & "\" & "Packages\" & Name & ";" & MemberElement.text
				Redim Preserve ExportTab(UBound(ExportTab)+1)
			Next
		End If
	End If
Next
Set xmlDoc = Nothing
Set xmlDoc = CreateObject("Microsoft.XMLDOM")
xmlDoc.Async = "false"
xmlDoc.Load(S_DP & "\control\Packages.xml")
For Each guidElement In xmlDoc.selectNodes("/packages/package")
	guid =  guidElement.getAttribute("guid")
	For i = 0 To (Ubound(ExportTab) -1)
		temp = Split(ExportTab(i),";")
		If Temp(1) = guid Then
			Source = guidElement.selectSingleNode("Source").text
			Source = S_DP & "\" & right(Source,Len(Source)-2)
			Source = Left(Source, InStrRev(Source, "\")-1)
			wscript.echo Source
			Temp2 = Split(Source,"\")
			wscript.Echo Temp(0) & "\" & Temp2(Ubound(Temp2))
			If Fso.FolderExists(Temp(0) & "\" & Temp2(Ubound(Temp2))) = False Then CodeRetour = Fso.CopyFolder(Source,Temp(0) & "\",True)

		End If
	Next
Next

' #################### export Operating system ####################################
wscript.echo "##### OS #####"
redim ExportTab(0)
Set xmlDoc = Nothing
Set xmlDoc = CreateObject("Microsoft.XMLDOM")
xmlDoc.Async = "false"
xmlDoc.Load(S_DP & "\control\OperatingSystemGroups.xml")
For Each personneElement In xmlDoc.selectNodes("/groups/group")
	Name =  personneElement.selectSingleNode("Name").text
	If Name <> "hidden" and Name <> "default" Then
		If Fso.FolderExists(S_Export & "\" & "OS") = False 		Then CodeRetour = Fso.CreateFolder(S_Export & "\" & "OS")
		If Fso.FolderExists(S_Export & "\" & "OS\" & Name) = False Then CodeRetour = Fso.CreateFolder(S_Export & "\" & "OS\" & Name)
		Set Member = personneElement.selectNodes("Member")
		If Member.length > 0 Then
			For Each MemberElement In Member
				ExportTab(UBound(ExportTab)) = S_Export & "\" & "OS\" & Name & ";" & MemberElement.text
				Redim Preserve ExportTab(UBound(ExportTab)+1)
			Next
		End If
	End If
Next
Set xmlDoc = Nothing
Set xmlDoc = CreateObject("Microsoft.XMLDOM")
xmlDoc.Async = "false"
xmlDoc.Load(S_DP & "\control\OperatingSystems.xml")
For Each guidElement In xmlDoc.selectNodes("/oss/os")
	guid =  guidElement.getAttribute("guid")
	For i = 0 To (Ubound(ExportTab) -1)
		temp = Split(ExportTab(i),";")
		If Temp(1) = guid Then
		
			Source = guidElement.selectSingleNode("Source").text
			Source = S_DP & "\" & right(Source,Len(Source)-2)
			wscript.echo Source
			Temp2 = Split(Source,"\")
			wscript.Echo Temp(0) & "\" & Temp2(Ubound(Temp2))
			CodeRetour = Fso.CopyFolder(Source,Temp(0) & "\" & Temp2(Ubound(Temp2)),True)

		End If
	Next
Next

' #################### export applications ####################################
wscript.echo "##### Applications #####"
redim ExportTab(0)
Set xmlDoc = Nothing
Set xmlDoc = CreateObject("Microsoft.XMLDOM")
xmlDoc.Async = "false"
xmlDoc.Load(S_DP & "\control\ApplicationGroups.xml")
For Each personneElement In xmlDoc.selectNodes("/groups/group")
	Name =  personneElement.selectSingleNode("Name").text
	If Name <> "hidden" and Name <> "default" Then
		If Fso.FolderExists(S_Export & "\" & "Applications") = False 		Then CodeRetour = Fso.CreateFolder(S_Export & "\" & "Applications")
		If Fso.FolderExists(S_Export & "\" & "Applications\" & Name) = False Then CodeRetour = Fso.CreateFolder(S_Export & "\" & "Applications\" & Name)
		Set Member = personneElement.selectNodes("Member")
		If Member.length > 0 Then
			For Each MemberElement In Member
				ExportTab(UBound(ExportTab)) = S_Export & "\" & "Applications\" & Name & ";" & MemberElement.text
				Redim Preserve ExportTab(UBound(ExportTab)+1)
			Next
		End If
	End If
Next
Set xmlDoc = Nothing
Set xmlDoc = CreateObject("Microsoft.XMLDOM")
xmlDoc.Async = "false"
xmlDoc.Load(S_DP & "\control\Applications.xml")
For Each guidElement In xmlDoc.selectNodes("/applications/application")
	guid =  guidElement.getAttribute("guid")
	For i = 0 To (Ubound(ExportTab) -1)
		temp = Split(ExportTab(i),";")
		If Temp(1) = guid Then
			Source = guidElement.selectSingleNode("Source").text
			Source = S_DP & "\" & right(Source,Len(Source)-2)
			wscript.echo Source
			Temp2 = Split(Source,"\")
			wscript.Echo Temp(0) & "\" & Temp2(Ubound(Temp2))

			CodeRetour = Fso.CopyFolder(Source,Temp(0) & "\" & Temp2(Ubound(Temp2)),True)

		End If
	Next
Next
Set xmlDoc = Nothing




Function GetPath()
 	Dim path
	path = WScript.ScriptFullName
	GetPath = Left(path, InStrRev(path, "\"))
End Function



