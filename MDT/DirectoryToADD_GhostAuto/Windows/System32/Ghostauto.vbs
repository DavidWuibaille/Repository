Const HKEY_LOCAL_MACHINE = &H80000002
strComputer = "."
Set Fso = CreateObject("Scripting.FileSystemObject")
Set Shell = CreateObject("WScript.Shell")

NomOrdinateur = ""
If Fso.FolderExists("c:\Windows") = True Then shell.Run "reg.exe load HKLM\0000 " & chr(34) & "C:\WINDOWS\system32\config\system" & Chr(34),0,True
If Fso.FolderExists("d:\Windows") = True Then shell.Run "reg.exe load HKLM\0000 " & chr(34) & "d:\WINDOWS\system32\config\system" & Chr(34),0,True
Set objRegistry=GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\default:StdRegProv")
strKeyPath = "0000\ControlSet001\Control\ComputerName\ComputerName"
strValueName = "Computername"
objRegistry.GetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,NomOrdinateur
shell.Run "cmd /c reg.exe unload HKLM\0000",0,True

If NomOrdinateur = "" Then
	NomOrdinateur = inputbox("Entrer le nom de l'ordinateur","Nom ordinateur")
End If


Dim letter
letter = array("c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z")

For i = 0 To Ubound(letter)
	If Fso.FolderExists(letter(i) & ":\ghost") Then
		PathHDD = letter(i) & ":\ghost"
	End If
Next

Namefile = PathHDD & "\" & NomOrdinateur & ".gho"
result = MsgBox ("Ghost auto ?", vbYesNo, Namefile)
Select Case result
Case vbYes
    Coderetour = shell.run(chr(34) & GetPath & "GHOST32.EXE" & chr(34) & " -z1 -clone,mode=dump,src=1,dst=" & Namefile & " -sure -split=2048 -auto -cns",,True)
	Msgbox "Code retour ghost : " & Coderetour
End Select

Function GetPath()
 Dim path
 Deftpath = WScript.ScriptFullName
 GetPath = Left(Deftpath, InStrRev(Deftpath, "\"))
End Function

