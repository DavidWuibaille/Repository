Param(
    [parameter(Mandatory=$true)][String]$Mycomputer
)

$remote = $Mycomputer


write-host "----------- $Mycomputer ----------------"
If (test-path "\\$Mycomputer\d$\sdmcache\RefInst") 										{ invoke-command -computername $Mycomputer -ScriptBlock {Remove-Item -Path "d:\sdmcache\RefInst\*" -Force -Recurse} }
If (test-path "\\$Mycomputer\d$\sdmcache\vboot")   										{ invoke-command -computername $Mycomputer -ScriptBlock {Remove-Item -Path "d:\sdmcache\vboot\*" -Force -Recurse} }
If (test-path "\\$Mycomputer\c$\Program Files (x86)\LANDesk\LDClient\SDMCache\refinst") { invoke-command -computername $Mycomputer -ScriptBlock {Remove-Item -Path "c:\Program Files (x86)\LANDesk\LDClient\SDMCache\refinst\*" -Force -Recurse} }
If (test-path "\\$Mycomputer\c$\Program Files (x86)\LANDesk\LDClient\SDMCache\vboot")   { invoke-command -computername $Mycomputer -ScriptBlock {Remove-Item -Path "c:\Program Files (x86)\LANDesk\LDClient\SDMCache\vboot\*" -Force -Recurse} }

If (test-path "\\$Mycomputer\d$\Master$\ImagesPos7") 									{ invoke-command -computername $Mycomputer -ScriptBlock {Remove-Item -Path "d:\Master$\ImagesPos7\*" -Force -Recurse} }
If (test-path "\\$Mycomputer\d$\Master$\ImagesW7") 										{ invoke-command -computername $Mycomputer -ScriptBlock {Remove-Item -Path "d:\Master$\ImagesW7\*" -Force -Recurse} }
If (test-path "\\$Mycomputer\d$\Master$\ImagesW8") 										{ invoke-command -computername $Mycomputer -ScriptBlock {Remove-Item -Path "d:\Master$\ImagesW8\*" -Force -Recurse} }
If (test-path "\\$Mycomputer\d$\Master$\RefInst\ToolsW7") 								{ invoke-command -computername $Mycomputer -ScriptBlock {Remove-Item -Path "d:\Master$\RefInst\ToolsW7\*" -Force -Recurse} }
If (test-path "\\$Mycomputer\d$\Master$\RefInst\Store\Master\ImagesW10\x64\MUI_LTSB") 			{ invoke-command -computername $Mycomputer -ScriptBlock {Remove-Item -Path "d:\Master$\RefInst\Store\Master\ImagesW10\x64\MUI_LTSB\*" -Force -Recurse} }
If (test-path "\\$Mycomputer\d$\Master$\RefInst\Store\Master\ImagesW10\x64\MUI_LTSC2019") 		{ invoke-command -computername $Mycomputer -ScriptBlock {Remove-Item -Path "d:\Master$\RefInst\Store\Master\ImagesW10\x64\MUI_LTSC2019\*" -Force -Recurse} }
If (test-path "\\$Mycomputer\d$\Master$\RefInst\Store\Master\ImagesW2016\x64\ENUS") 			{ invoke-command -computername $Mycomputer -ScriptBlock {Remove-Item -Path "d:\Master$\RefInst\Store\Master\ImagesW2016\x64\ENUS\*" -Force -Recurse} }
If (test-path "\\$Mycomputer\d$\Master$\RefInst\Store\Master\ImagesW2016\x64\ENUS") 			{ invoke-command -computername $Mycomputer -ScriptBlock {Remove-Item -Path "d:\Master$\RefInst\Store\Master\ImagesW2016\x64\ENUS\*" -Force -Recurse} }
If (test-path "\\$Mycomputer\d$\Master$\RefInst\SCX") 			{ invoke-command -computername $Mycomputer -ScriptBlock {Remove-Item -Path "d:\Master$\RefInst\SCX\*" -Force -Recurse} }
