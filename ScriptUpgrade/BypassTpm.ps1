# Path to the registry key
$labConfigPath = "HKLM:\SYSTEM\Setup\LabConfig"
$moSetupPath = "HKLM:\SYSTEM\Setup\MoSetup"
 
# Check if the LabConfig registry key exists, otherwise create it
if (-not (Test-Path $labConfigPath)) {
    New-Item -Path "HKLM:\SYSTEM\Setup" -Name "LabConfig" -Force | Out-Null
}
 
# Add properties to bypass checks
$bypassChecks = @("CPU", "RAM", "SecureBoot", "Storage", "TPM")
foreach ($check in $bypassChecks) {
    Set-ItemProperty -Path $labConfigPath -Name "Bypass$check`Check" -Value 1 -Type DWORD -Force
}
 
# Add property to allow upgrade with unsupported TPM or CPU
if (-not (Test-Path $moSetupPath)) {
    New-Item -Path "HKLM:\SYSTEM\Setup" -Name "MoSetup" -Force | Out-Null
}
 
Set-ItemProperty -Path $moSetupPath -Name "AllowUpgradesWithUnsupportedTPMorCPU" -Value 1 -Type DWORD -Force
 
 
# Path to the executable
$executablePath = "c:\ISOWindows11\Sources\setupprep.exe"
 
# Command arguments
$args = @(
    "/SelfHost"
    "/Auto Upgrade"
    "/MigChoice Upgrade"
    "/Compat IgnoreWarning"
    "/MigrateDrivers All"
    "/ResizeRecoveryPartition Disable"
    "/ShowOOBE None"
    "/Telemetry Disable"
    "/CompactOS Disable"
    "/DynamicUpdate Enable"
    "/SkipSummary"
    "/Eula Accept"
) -join " "
 
# Execute the command and wait for completion
$process = Start-Process -FilePath $executablePath -ArgumentList $args -Wait -NoNewWindow -PassThru
 
# Retrieve the exit code
$returnCode = $process.ExitCode
 
# Display the exit code
write-host $returnCode"