
$local_key       = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
$machine_key     = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
$machine_key6432 = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'

[array]$keys = Get-ChildItem -Path @($machine_key6432, $machine_key, $local_key) -ErrorAction SilentlyContinue
    foreach ($key in $keys){

        $DisplayName = $key.getValue('DisplayName')
        $UninstallString = $key.getValue('UninstallString')
        If ($displayName -like "*Acrobat Reader*") {
            if (($UninstallString -like "msiexec*") -and ($UninstallString -like '*{*')) {
                $Temp = $UninstallString.split('{')
                $UninstallString = $Temp[1]
                $UninstallString = "{$UninstallString"
                write-host $UninstallString
                Start-Process -FilePath "c:\windows\system32\msiexec.exe" -ArgumentList "/X $UninstallString REBOOT=ReallySuppress /qn" -wait -NoNewWindow
            }
        }
    }
    write-host "***End***"