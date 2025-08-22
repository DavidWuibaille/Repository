'############# PageFile ##########################
Const HKCU = &H80000001
Const HKLM = &H80000002
Const HKU  = &H80000003

Set shell = CreateObject("WScript.Shell")
Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & "." & "\root\default:StdRegProv")

strComputer = "."
Pagefilemin = 4095
Pagefilemax = 4095

Set objWMI = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2") 
Set colComputer = objWMI.ExecQuery ("Select * from Win32_ComputerSystem") 

For Each objComputer in colComputer 
	RAM = Cint(objComputer.TotalPhysicalMemory / 1024 /1024)
Next 

Pagefilemin = (RAM * 3 / 2)
Pagefilemax = (RAM * 3 / 2)

If Pagefilemax > 4095 Then Pagefilemax = 4095
If Pagefilemin > 4095 Then Pagefilemin = 4095

strKeyPath      = "SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
strValueName    = "PagingFiles"

arrStringValues = Array("C:\pagefile.sys " & Pagefilemin & " " & Pagefilemax)

oReg.SetMultiStringValue HKLM,strKeyPath,strValueName,arrStringValues
Set objWMIService = Nothing
Set oReg          = Nothing


 

