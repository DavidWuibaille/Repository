Const CSIDL_COMMON_PROGRAMS = &H17
Const CSIDL_PROGRAMS = &H2
Set FSO = CreateObject("Scripting.FileSystemObject")
Set Shell = CreateObject("WScript.Shell")

Dim Destination
Destination = Shell.ExpandEnvironmentStrings(("%APPDATA%") & "\Microsoft\Internet Explorer\Quick Launch\User Pinned\StartMenu\Mozilla Firefox.lnk")
If FSO.FileExists(Destination) = True Then
    FSO.DeleteFile Destination
Else
    On Error Resume Next
End If

Set objShell = CreateObject("Shell.Application")
Set objAllUsersProgramsFolder = objShell.NameSpace("C:\ProgramData\Microsoft\Windows\Start Menu")
strAllUsersProgramsPath = objAllUsersProgramsFolder.Self.Path
Set objFolder = objShell.Namespace(strAllUsersProgramsPath)
Set objFolderItem = objFolder.ParseName("Mozilla Firefox.lnk")
Set colVerbs = objFolderItem.Verbs
For Each objVerb in colVerbs
    If InStr(UCase(objVerb.Name), "MENU") <> 0 And InStr(UCase(objVerb.Name), "MARRER") <> 0 Then
        objVerb.DoIt
    End If
Next