Set Fso = CreateObject("Scripting.FileSystemObject")
Set Shell = CreateObject("WScript.Shell")

Const scan = "c:\sysprep"

Set inf_W = Fso.CreateTextFile(scan & "\sysprep.inf" , True)
inf_W.WriteLine "[Unattended]"
inf_W.WriteLine "DriverSigningPolicy = Ignore"
inf_W.WriteLine ""


inf_W.WriteLine "[SysprepMassStorage]"


Call FindFile(scan)

inf_W.WriteLine ""
inf_W.WriteLine "[Sysprep]"
inf_W.WriteLine "BuildMassStorageSection = Yes"



   

Sub FindFile(dossier)
        Set fs=fso.GetFolder(dossier)

        'traitement des fichiers
        Set collfiles = fs.Files
        For Each File In collfiles
            If Right(UCase(file.name),3) = "INF" Then Call AnalyseINF(dossier & "\" & file.name)

        Next 'File

        'traitement des sous dossier
        Set collfolders = fs.SubFolders
        For each folder in collfolders
			curfolder = dossier & "\" & folder.name
			call FindFile(curfolder)
        Next
End Sub


Sub AnalyseINF(fileINF)
	
	Set inf = Fso.OpenTextFile(fileINF, 1, false)
        While inf.AtEndOfStream <> True
            Ligne = Inf.Readline
				If Instr(UCase(Ligne),"VEN_") <> 0 Then
					If Instr(UCase(Ligne),"EXCLUDEFROMSELECT") = 0 Then
						If Left(Ligne,1) <> ";" Then 
							If Instr(Ligne,",") <> 0 Then
								If Instr(Ligne,"=") <> 0 Then
									If Right(Trim(Ligne),1) <> chr(34) Then
										Temp = Split(Ligne,"=")
										MonVEN = Split(Temp(1),",")
										MonVEN(1) = Replace(MonVEN(1),chr(9),"")
										If Instr(MonVEN(1),";") <> 0 Then
											Net = Split(MonVEN(1),";")
											inf_W.WriteLine	Trim(Net(0)) & "=" & fileINF
										Else
											inf_W.WriteLine	TRim(MonVEN(1)) & "=" & fileINF
										End If
									End If
									
								End If
							End If
						End If
					End If
					
				
				End If

		Wend
		inf.close
	



End Sub