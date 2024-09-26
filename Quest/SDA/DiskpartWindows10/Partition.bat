wpeutil UpdateBootInfo

for /f "tokens=2*" %%A in ('REG QUERY "HKLM\System\CurrentControlSet\Control" /v PEFirmwareType') DO (
  for %%F in (%%B) do (
    set Firmware=%%F
  )
)



If %Firmware%==0x1 Diskpart /s "%~dp0BIOS.TXT"
If %Firmware%==0x2 Diskpart /s "%~dp0UEFI.TXT"

pause