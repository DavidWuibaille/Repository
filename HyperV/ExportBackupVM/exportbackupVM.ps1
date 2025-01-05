# Define paths
$exportPath = "D:\export"
$backupPath = "\\192.168.0.3\backup\VM"

# Check and create export directory
if (-Not (Test-Path -Path $exportPath)) {
    New-Item -ItemType Directory -Path $exportPath -Force | Out-Null
}

# Clear the export directory
Get-ChildItem -Path $exportPath -Recurse | Remove-Item -Force -Recurse

# Get VMs containing "Backup_" in the name
$vmList = Get-VM | Where-Object { $_.Name -like "*Backup_*" }

if ($vmList.Count -eq 0) {
    Write-Host "No VMs found with 'Backup_' in the name." -ForegroundColor Yellow
    return
}

# Export VMs
foreach ($vm in $vmList) {
    $exportDestination = Join-Path -Path $exportPath -ChildPath $vm.Name
    Export-VM -Name $vm.Name -Path $exportDestination
    Write-Host "Exported VM: $($vm.Name) to $exportDestination"
}

# Copy exported files to the backup path
if (Test-Path -Path $backupPath) {
    Copy-Item -Path "$exportPath\*" -Destination $backupPath -Recurse -Force
    Write-Host "Files copied to $backupPath"
} else {
    Write-Host "Backup path not found: $backupPath" -ForegroundColor Red
    return
}

# Clear the export directory after copying
Get-ChildItem -Path $exportPath -Recurse | Remove-Item -Force -Recurse
Write-Host "Export directory cleared: $exportPath"
