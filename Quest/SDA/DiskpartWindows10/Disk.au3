
#include <MsgBoxConstants.au3>

Local $iPID = RunWait("winpeinit", "", @SW_SHOWMAXIMIZED)


Local $sVar = RegRead("HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control", "PEFirmwareType")


If $sVar = 1 Then
   MsgBox($MB_SYSTEMMODAL, "Diskpart","BIOS",3)
 Local $iPID = RunWait("diskpart /s bios.txt", "", @SW_SHOWMAXIMIZED)
Else
   MsgBox($MB_SYSTEMMODAL, "Diskpart","UEFI",3)
 Local $iPID = RunWait("diskpart /s UEFI.txt", "", @SW_SHOWMAXIMIZED)
EndIf













