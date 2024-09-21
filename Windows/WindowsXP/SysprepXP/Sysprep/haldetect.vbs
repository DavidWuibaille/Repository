'on error resume next
' -------------------------------------------------------------------------------------
' Script de detection de HAL dans un environnement WinPE
' Necessite un sous repertoire nomme "HAL" contenant les fichiers HAL
' OS supporté Windows XP SP3 
' Version Script 1.2
' Amelioration:
'		- Utilisable depuis un chemin UNC
'		- Correction d'un bug de copie
' -------------------------------------------------------------------------------------



Set FSO = CreateObject("Scripting.FileSystemObject")
Set Shell = CreateObject("WScript.Shell")


sSysprepInf = "c:\sysprep\Sysprep.inf"

sHalType = Shell.RegRead("HKLM\SYSTEM\CurrentControlSet\Enum\Root\ACPI_HAL\0000\HardwareID")
If sHalType(0) = "acpiapic" Then
	if Shell.Environment.item("NUMBER_OF_PROCESSORS") = 1 then
		Call CopyHalFiles("ACPIAPIC_UP")
		WriteProfileString "Unattended", "UpdateUPHAL", sSysprepInf, "ACPIAPIC_UP,C:\Windows\Inf\Hal.inf"
	else
		Call CopyHalFiles("ACPIAPIC_MP")
		WriteProfileString "Unattended", "UpdateHAL", sSysprepInf, "ACPIAPIC_MP,C:\Windows\Inf\Hal.inf"
	end if
End If
	
If sHalType(0) = "acpiapic_up" Then
	Call CopyHalFiles("ACPIAPIC_UP")
	WriteProfileString "Unattended", "UpdateUPHAL", sSysprepInf,"ACPIAPIC_UP,C:\Windows\Inf\Hal.inf"
End If	
	
If sHalType(0) = "acpiapic_mp" Then
	Call CopyHalFiles("ACPIAPIC_MP")
	WriteProfileString  "Unattended", "UpdateHAL", sSysprepInf, "ACPIAPIC_MP,C:\Windows\Inf\Hal.inf"
End If

Sub CopyHalFiles(Montype)
	sSourceFolder = "c:\sysprep\HAL"
	sDestinationFolder = "c:\Windows\System32"

	If StrComp(Montype, "ACPIAPIC_UP") = 0 Then
		FSO.CopyFile sSourceFolder & "\halaacpi.dll", sDestinationFolder & "\hal.dll", true
		FSO.CopyFile sSourceFolder & "\ntkrnlpa.exe", sDestinationFolder & "\ntkrnlpa.exe", true
		FSO.CopyFile sSourceFolder & "\ntoskrnl.exe", sDestinationFolder & "\ntoskrnl.exe", true
	End If

	If StrComp(Montype, "ACPIAPIC_MP") = 0 Then
		FSO.CopyFile sSourceFolder & "\halmacpi.dll", sDestinationFolder & "\hal.dll", true
		FSO.CopyFile sSourceFolder & "\ntkrpamp.exe", sDestinationFolder & "\ntkrnlpa.exe", true
		FSO.CopyFile sSourceFolder & "\ntkrnlmp.exe", sDestinationFolder & "\ntoskrnl.exe", true
	End If

	If StrComp(Montype, "ACPIPIC_UP") = 0 Then
		FSO.CopyFile sSourceFolder & "\halacpi.dll",  sDestinationFolder & "\hal.dll", true
		FSO.CopyFile sSourceFolder & "\ntkrnlpa.exe", sDestinationFolder & "\ntkrnlpa.exe", true
		FSO.CopyFile sSourceFolder & "\ntoskrnl.exe", sDestinationFolder & "\ntoskrnl.exe", true
	End If
End Sub

Function GetPath()
	Dim Path
	Path = WScript.ScriptFullName
	GetPath = Left(Patch, InStrRev(Path,"\"))
End Function

' Ecriture d'un fichier ini
Sub WriteProfileString(section,key,filename,value)
Dim fso
  Set fso = CreateObject("scripting.filesystemobject")  
  If MyTrim(section)="" Or Mytrim(key)="" then
    Exit Sub
  End If    
  dim contentini
  contentini=""  
  if fso.FileExists(filename) then
    Dim readini,bsection,bSectionFound,bKeyFound
    bKeyFound=False
    bsection=False
    bsectionFound=False    
    Set readini = fso.OpenTextFile(filename,1)
    Do while not(readini.AtEndOfStream)
      Dim strini,trimstrini
      strini = readini.ReadLine
      trimstrini = MyTrim(strini)
      if Left(trimstrini,1)="[" and Right(Trimstrini,1)="]" then
        if StrComp(Trimstrini,"[" & MyTrim(section) & "]",1)=0 Then
          bsection=True
          bsectionFound=True
        else
          bsection =False
        end if
      Else
        if bsection then
          Dim poskey
          poskey = InStr(Trimstrini,"=")
          if posKey>0 then
            if StrComp(MyTrim(Left(Trimstrini,poskey-1)),MyTrim(key),1)=0 Then
              bKeyFound = True
              strini = Left(Trimstrini,poskey) & " " & value
            end If  
          End if
        end if
      End if      
      if bsectionFound=True and bsection=False and bKeyFound=false then
        contentini = contentini & key & "=" & value & vbcrlf
        bKeyFound = True
      end if      
      if MyTrim(strini)<>"" then
        if Left(trimstrini,1)="[" and Right(Trimstrini,1)="]" And contentini<>"" then
          contentini = contentini & vbCrlf
        end if       
        contentini = contentini & strini & vbCrlf
      end if
    Loop
    if bsectionFound=True and bsection=True and bKeyfound =false then
      contentini = contentini & key & "=" & value & vbcrlf
    end if    
    if bsectionFound=False Then
      contentini = contentini & vbcrlf & "[" & section & "]" & vbcrlf & key & "=" & value & vbcrlf
    end if    
    readini.Close    
  Else
    contentini = "[" & section & "]" & vbcrlf & key & "=" & value & vbcrlf
  End if  
  Dim writeini 
  set writeini = fso.CreateTextFile(filename,True)
  writeini.Write contentini
  writeini.Close
End Sub

Function MyTrim(mystring)
  Dim start,Endpos
  start=1
  for i=1 to Len(mystring)
    if Mid(mystring,i,1)=vbTab or Mid(mystring,i,1)=" " Then
      start=i+1
    else
      exit for
    end if
  next
  Endpos=Len(mystring)
  for i=Len(mystring) to 1 step -1
    if Mid(mystring,i,1)=vbTab or Mid(mystring,i,1)=" " Then
      Endpos=i-1
    else
      exit for
    end if
  next
  if (endpos-start+1)<0 then
    MyTrim=""
    Exit Function
  end if
  MyTrim=Mid(mystring,start,Endpos-start+1)
End Function
