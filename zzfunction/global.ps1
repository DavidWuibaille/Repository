function Write-Log {
    param (
        [string]$LogFile,     # Full path of the log file
        [string]$Message      # Message to write to the log file
    )

    # Extract the directory path from the log file path
    $LogDir = Split-Path -Path $LogFile -Parent

    # Check if the directory exists, and create it if it doesn't
    if (-not (Test-Path -Path $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    }

    # Get the current date and time in the format "yyyy-MM-dd HH:mm:ss"
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Construct the log entry with the timestamp and message
    $LogEntry = "[${Timestamp}] $Message"

    # Append the log entry to the log file
    Add-Content -Path $LogFile -Value $LogEntry
}
