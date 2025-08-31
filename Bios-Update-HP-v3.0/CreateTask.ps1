# 1) Define paths
$sourcePath = "$PSScriptRoot\*"
$destinationPath = "C:\Windows\Temp\Bios"
$logFiles = "$destinationPath\sp156628\HpFirmwareUpdRec*.log"
$cacheFolder = "$destinationPath\sp156628\ldcacheinfo"

# 2) Remove the target folder if it exists
if (Test-Path $destinationPath) {
    Remove-Item -Path $destinationPath -Recurse -Force -ErrorAction SilentlyContinue
}

# 3) Recreate the target folder
New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null

# 4) Copy files
Write-Host "Copying BIOS files to '$destinationPath'..."
Copy-Item -Path $sourcePath -Destination $destinationPath -Recurse -Force

# 5) Delete log files if they exist
if (Test-Path $logFiles) {
    Remove-Item -Path $logFiles -Force -ErrorAction SilentlyContinue
}

# 6) Delete the ldcacheinfo folder if it exists
if (Test-Path $cacheFolder) {
    Remove-Item -Path $cacheFolder -Recurse -Force -ErrorAction SilentlyContinue
}

# 7) Define the scheduled task name
$taskName = "BiosUpdateAtStartup"

Write-Host "Creating scheduled task '$taskName' to run the BIOS update at startup..."

# 8) Define the action: Run the script in silent mode
$scriptPath = "$destinationPath\BIOS_Update.bat"
if (-not (Test-Path $scriptPath)) {
    Write-Host "Error: The file '$scriptPath' was not found!" -ForegroundColor Red
    exit 1
}

$action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c `"$scriptPath`""

# 9) Set execution as SYSTEM with highest privileges
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest

# 10) Define the trigger with a 2-minute delay (ISO 8601: PT2M)
$trigger = New-ScheduledTaskTrigger -AtStartup
$trigger.Delay = "PT2M"

# 11) Check for and remove any existing task
if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Write-Host "Existing task detected. Removing..."
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

# 12) Create and register the new scheduled task
$scheduledTask = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal
Register-ScheduledTask -TaskName $taskName -InputObject $scheduledTask | Out-Null

Write-Host "Scheduled task '$taskName' successfully created. It will run at startup with a 2-minute delay."
