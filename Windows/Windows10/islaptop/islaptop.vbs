


If CheckTypePC <> "Desktop" Then
	WScript.quit 1
Else
	WScript.quit 0
End If





Function CheckTypePC ()
    On Error Resume Next
    Dim objWMIService,colItems,objItem
    Set objWMIService = GetObject("winmgmts:\\.\root\cimv2")
    Set colItems = objWMIService.ExecQuery("Select DeviceID from Win32_PCMCIAController",,48)
    For Each objItem in colItems
        If Not (objItem.DeviceID = "") Then
	       CheckTypePC = "Notebook"
           Exit For
	    End If 
    Next

    Set colItems = objWMIService.ExecQuery("Select DeviceID from Win32_PortableBattery",,48)
    For Each objItem in colItems
        If Not (objItem.DeviceID = "") Then
	       CheckTypePC = "Notebook"
           Exit For
	    End If 
    Next
    Set colItems = objWMIService.ExecQuery("Select DeviceID from Win32_Battery",,48)
    For Each objItem in colItems
        If Not (objItem.DeviceID = "") Then
	       CheckTypePC = "Notebook"
           Exit For
	    End If 
    Next




    If CheckTypePC = "" Then CheckTypePC = "Desktop"
    Set objWMIService = Nothing
End Function

