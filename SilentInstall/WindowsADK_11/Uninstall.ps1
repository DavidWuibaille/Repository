#"C:\ProgramData\Package Cache\{39ebb79f-797c-418f-b329-97cfdf92b7ab}\adksetup.exe" /uninstall /quiet
#"C:\ProgramData\Package Cache\{75ed7648-6cdf-4e09-b2fe-41e985652c96}\adksetup.exe" /uninstall /quiet
#"C:\ProgramData\Package Cache\{cef137de-cdb9-48e2-babe-301cb8448d7b}\adksetup.exe" /uninstall /quiet


$local_key       = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
$machine_key     = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
$machine_key6432 = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'

[array]$keys = Get-ChildItem -Path @($machine_key6432, $machine_key, $local_key) -ErrorAction SilentlyContinue
    foreach ($key in $keys){

        $DisplayName = $key.getValue('DisplayName')
        $UninstallString = $key.getValue('UninstallString')
        If (($displayName -like "Windows Assessment and Deployment Kit*") -or ($displayName -like "*Kit de d*ploiement et d*valuation Windows*")){
            $temp = $UninstallString.split(".")
            $UninstallString = $Temp[0]+".exe"""
            write-host $UninstallString

            Start-Process -FilePath $UninstallString -ArgumentList "/uninstall /quiet /norestart" -wait
        }
    }
