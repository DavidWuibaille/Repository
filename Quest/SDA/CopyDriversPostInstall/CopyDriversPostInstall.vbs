' add custom
Const HKEY_LOCAL_MACHINE = &H80000002
KacepathUSB = "\KACE\drivers_postinstall\"
Kacepath = "y:\drivers_postinstall\"

CopyLocal = "c:\dsi"
Set Fso = CreateObject("Scripting.FileSystemObject")
Set Shell = CreateObject("Wscript.Shell")


'----------> Get Deployment support
on error resume next
UFDPATH = Shell.ExpandEnvironmentStrings("%UFDPATH%") & "\kace\deploy.bat"
If Fso.FileExists(UFDPATH) Then
	KacepathUSB = Shell.ExpandEnvironmentStrings("%UFDPATH%") & KacepathUSB
End If
On error goto 0

' ---------> Log File
If Fso.FileExists(UFDPATH) Then
	FichierLog = Shell.ExpandEnvironmentStrings("%UFDPATH%") & "\Drivers.log"
Else
	FichierLog = "t:\Drivers.log"
End If

'----------> Get Manufacturer
wmiQuery = "Select * from win32_ComputerSystem"
Set objWMIService = GetObject("winmgmts:\\")
Set colItems = objWMIService.ExecQuery(wmiQuery)
For Each objItem in ColItems
    strManufacturer = objItem.Manufacturer
	TraceLog FichierLog , "strManufacturer (WMI) = " & strManufacturer
	strManufacturer = Trim(UCase(strManufacturer))
    If (InStr(strManufacturer ,"DELL") > 0) 			Then strManufacturer = "DELL"
    If (InStr(strManufacturer ,"HEWLETT-PACKARD") > 0) 	Then strManufacturer = "HP"
	If (InStr(strManufacturer ,"LENOVO") > 0) 			Then strManufacturer = "LENOVO"
    If (InStr(strManufacturer ,"VMWARE") > 0)  			Then strManufacturer = "VMWARE"
    If (InStr(strManufacturer ,"SAMSUNG") > 0) 			Then strManufacturer = "SAMSUNG"
	If (InStr(strManufacturer ,"TOSHIBA") > 0) 			Then strManufacturer = "TOSHIBA"
	If (InStr(strManufacturer ,"PANASONIC") > 0) 		Then strManufacturer = "PANASONIC"
Next
strManufacturer = Replace(strManufacturer, " ", "_")
strManufacturer = Replace(strManufacturer, " /", "_")
TraceLog FichierLog , "strManufacturer (Clean) = " & strManufacturer

'----------> Get model
If strManufacturer = "LENOVO" Then
		wmiQuery = "Select * from win32_ComputerSystemProduct" 
		Set objWMIService = GetObject("winmgmts:\\") 
		Set colItems1 = objWMIService.ExecQuery(wmiQuery) 
		For Each objItem1 in ColItems1
			strModel = objItem1.Version
			TraceLog FichierLog , "strModel (WMI) = " & strModel
			strModel = Ucase(strModel)
			strModel = Trim(strModel) 
		Next
Else
	wmiQuery = "Select * from win32_ComputerSystem"
	Set objWMIService = GetObject("winmgmts:\\")
	Set colItems = objWMIService.ExecQuery(wmiQuery)
	For Each objItem in ColItems 
		strModel = objItem.Model
		TraceLog FichierLog , "strModel (WMI) = " & strModel
		strModel = Trim(UCase(strModel))
		' ------> Dell
		If (InStr(strModel,"LATITUDE")  			> 0) 	Then strModel = mid(strModel,9,20)
		If (InStr(strModel," VPRO") 				> 0) 	Then strModel = Replace(strModel, " VPRO", "")
		If (InStr(strModel," NON-VPRO") 			> 0) 	Then strModel = Replace(strModel, " NON-VPRO", "") 
		If (InStr(strModel,"PRECISION") 			> 0)	Then strModel = mid(strModel,10,21)
		If (InStr(strModel,"OPTIPLEX") 				> 0) 	Then strModel = mid(strModel,9,20)
		If (InStr(strModel,"DELL SYSTEM") 			> 0) 	Then strModel = mid(strModel,12,21)
		If (InStr(strModel," AIO") 					> 0) 	Then strModel = Replace(strModel, " AIO", "-AIO")
		If (InStr(strModel,"10 - ")					> 0) 	Then strModel = "ST2"
		If (InStr(strModel,"Venue 11 Pro 7130 MS") 	> 0)	Then strModel = Replace(strModel, " MS", "")
		If strModel = "10" 									Then strModel = "ST2E"
		If strModel = "XPS 12 9Q23" 						Then strModel = "XPS-12-L221X"
		If strModel = "XPS 12-9Q33" 						Then strModel = "XPS-9Q33"
		If strModel = "XPS L521X" 							Then strModel = "XPS-15-L521X"
		
		' --------> VMWARE
		If (inStr(strModel,"VMWARE") 				> 0) 	Then strModel = "VMWARE"
		strModel = Trim(strModel)
	Next
End If
'strModel = Replace(strModel, " ", "_")
strModel = Replace(strModel, "/", "_")
TraceLog FichierLog , "strModel (Clean) = " & strModel

'----------> Get Architecture
strRegProArch = "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\PROCESSOR_ARCHITECTURE"
Set objshell = CreateObject("Wscript.Shell")
strArc = objshell.RegRead(strRegProArch)
If (InStr(UCase(strArc),"AMD64") > 0) 				Then strArc = "x64"
TraceLog FichierLog , "strArc (WINPE) = " & strArc

'----------> Get OS
ProductName = ""
If Fso.FolderExists("c:\Windows") = True Then Shell.Run "reg.exe load HKLM\0000 " & chr(34) & "C:\WINDOWS\system32\config\software" & Chr(34),0,True
Set objRegistry=GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & "." & "\root\default:StdRegProv")
strKeyPath = "0000\Microsoft\Windows NT\CurrentVersion"
strValueName = "ProductName"
objRegistry.GetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,ProductName
Shell.Run "cmd /c reg.exe unload HKLM\0000",0,True
TraceLog FichierLog , "ProductName (Registry) = " & ProductName

If instr(UCase(ProductName),"WINDOWS XP") 	<> 0 Then strOs = "Windows_XP"
If instr(UCase(ProductName),"WINDOWS 7")  	<> 0 Then strOs = "Windows_7"
If instr(UCase(ProductName),"WINDOWS 8")  	<> 0 Then strOs = "Windows_8"
If instr(UCase(ProductName),"VISTA")      	<> 0 Then strOs = "windows_vista"
If instr(UCase(ProductName),"2003")       	<> 0 Then strOs = "windows_2003"
If instr(UCase(ProductName),"2008")       	<> 0 Then strOs = "windows_2008"
If instr(UCase(ProductName),"2012")       	<> 0 Then strOs = "windows_2012"

strArc = "_" & strArc
If instr(UCase(ProductName),"WINDOWS XP") 		<> 0 Then strArc = ""
If instr(UCase(ProductName),"VISTA")      		<> 0 Then strArc = ""
If instr(UCase(ProductName),"2003")       		<> 0 Then strArc = ""
TraceLog FichierLog , "strOs (Clean) = " & strOs
TraceLog FichierLog , "strArc (Clean) = " & strArc

' ========> copy des drivers
If Fso.FolderExists(CopyLocal) = False Then CodeRetour = Fso.CreateFolder(CopyLocal)
If Fso.FolderExists(CopyLocal & "\drivers") = False Then CodeRetour = Fso.CreateFolder(CopyLocal & "\drivers")
If Fso.FolderExists(Kacepath & strManufacturer & "\" & strOs & strArc & "\" & strModel) Then
	wscript.echo "Copy : " & Kacepath & strManufacturer & "\" & strOs  & strArc & "\" & strModel
	TraceLog FichierLog , "### Copy = " & Kacepath & strManufacturer & "\" & strOs  & strArc & "\" & strModel
	CodeRetour = Fso.CopyFolder(Kacepath & strManufacturer & "\" & strOs  & strArc & "\" & strModel,CopyLocal & "\drivers",True)
Else
	If Fso.FolderExists(KacepathUSB & strManufacturer & "\" & strOs & strArc & "\" & strModel) Then
		wscript.echo "copy : " & KacepathUSB & strManufacturer & "\" & strOs  & strArc & "\" & strModel
		TraceLog FichierLog , "### Copy = " & KacepathUSB & strManufacturer & "\" & strOs  & strArc & "\" & strModel
		CodeRetour = Fso.CopyFolder(KacepathUSB & strManufacturer & "\" & strOs  & strArc & "\" & strModel,CopyLocal & "\drivers",True)
	End If
End If

' ========> Inject des drivers
TraceLog FichierLog , "### Inject Drivers = " & CopyLocal & "\drivers"
wscript.echo "Inject : " & "dism /image:c:\ /Add-driver /driver:" & CopyLocal & "\drivers /recurse /forceunsigned"
CodeRetour = Shell.run("dism /image:c:\ /Add-driver /driver:" & CopyLocal & "\drivers /recurse /forceunsigned",,True)

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


