function Uninstall {
    param (
        [Parameter(Mandatory=$true)] [string]$AppName,
        [Parameter(Mandatory=$false)] [string]$Arg = "/S"
    )
 
    # Define uninstall keys
    $uninstallKeys = @(
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
 
   # Define the log file path
    $logFilePath = "C:\Windows\temp\uninstall.log"
 
    # Fetch all keys
    $keys = Get-ChildItem -Path $uninstallKeys -ErrorAction SilentlyContinue
 
    # Filter and uninstall the specified app
    $keys | Where-Object {
        $_.GetValue('DisplayName') -like "*$AppName*"
    } | ForEach-Object {
        $uninstallString = $_.GetValue('UninstallString')
        $uninstallApps   = $_.GetValue('DisplayName')
         
        if ($uninstallString -like "msiexec*" -and $uninstallString -like '*{*') {
            $uninstallString = "{$($uninstallString.split('{')[1])"
             
            $logEntry = "$uninstallApps => msiexec.exe /X $uninstallString REBOOT=ReallySuppress /qn"
            Write-Host $logEntry
            Add-Content -Path $logFilePath -Value $logEntry        
            Start-Process -FilePath "c:\windows\system32\msiexec.exe" -ArgumentList "/X $uninstallString REBOOT=ReallySuppress /qn" -Wait
        } 
        if (($uninstallString -like "*.exe*") -and ($uninstallString -notlike "*msiexec*")) {
            $logEntry = "$uninstallApps => $uninstallString $Arg"
            Write-Host $logEntry
            Add-Content -Path $logFilePath -Value $logEntry
            Start-Process -FilePath "$uninstallString" -ArgumentList "$Arg" -Wait
        }
    }
}
 
 
Uninstall -AppName "Firefox" -Arg "-ms"
Uninstall -AppName "Teamviewer"
Uninstall -AppName "AnyDesk"