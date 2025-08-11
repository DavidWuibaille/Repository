
$local_key       = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
$machine_key     = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
$machine_key6432 = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'

[array]$keys = Get-ChildItem -Path @($machine_key6432, $machine_key, $local_key) -ErrorAction SilentlyContinue
    foreach ($key in $keys){

        $DisplayName = $key.getValue('DisplayName')
        $UninstallString = $key.getValue('UninstallString')
        If (($displayName -like "Plantronics Hub Software*") -and ($UninstallString -like "*/uninstall*")) {
            write-host $UninstallString
				
			$UninstallString = $UninstallString.replace("/uninstall","")
			$UninstallString = $UninstallString.trim()
			Start-Process -FilePath "$UninstallString" -ArgumentList "/uninstall /quiet /norestart" -wait
        }
    }
